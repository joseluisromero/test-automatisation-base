@EvaluacionKarate
Feature: Test de API súper simple

  Background:
    * configure ssl = true
    * def baseUrl = 'http://bp-se-test-cabcd9b246a5.herokuapp.com'
    * def randomString =
    """
    function(s) {
      var text = "";
      var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
      for (var i = 0; i < s; i++)
        text += possible.charAt(Math.floor(Math.random() * possible.length));
      return text;
    }
    """
    * def randomName = randomString(10)
    * def result = { characterId: null, characterName: null }

  Scenario: Verificar que un endpoint público responde 200
    Given url 'https://httpbin.org/get'
    When method get
    Then status 200

  @id:1 @ConsultaTodosLosPersonajes
  Scenario Outline: Consultar todos los personajes
    Given url baseUrl + '/<usuario>/api/characters'
    When method get
    Then status 200
    And match response != null

    Examples:
      | usuario    |
      | testuser  |

  @id:2 @CrearPersonaje
  Scenario Outline: Crear un nuevo personaje
    * def requestBody =
    """
    {
      "name": "#(randomName)",
      "alterego": "<alterego>",
      "description": "<description>",
      "powers": <powers>
    }
    """
    Given url baseUrl + '/<usuario>/api/characters'
    And header Content-Type = 'application/json'
    And request requestBody
    When method post
    Then status 201
    And match response != null
    And match response contains { name: '#(randomName)' }
    And match response.id != null
    * karate.set('characterId', response.id)
    * karate.set('characterName', response.name)
    * set result.characterId = response.id
    * set result.characterName = response.name
    * print 'Personaje creado con ID:', result.characterId

    Examples:
      | usuario   | alterego    | description        | powers                    |
      | testuser  | Tony Stark  | Genius billionaire | ["Armor", "Flight"]      |



  @id:4 @ActualizarPersonaje
  Scenario: Actualizar un personaje por id
    # Crear el personaje inicial
    * def createBody =
    """
    {
      "name": "#(randomName)",
      "alterego": "Tony Stark",
      "description": "Initial description",
      "powers": ["Armor", "Flight"]
    }
    """
    Given url baseUrl + '/testuser/api/characters'
    And header Content-Type = 'application/json'
    And request createBody
    When method post
    Then status 201
    And match response != null
    * set result.characterId = response.id
    * set result.characterName = response.name
    * print 'Personaje creado con ID:', result.characterId

    # Actualizar el personaje
    * def requestBody =
    """
    {
      "name": "Iron Man Updated",
      "alterego": "Tony Stark",
      "description": "Updated description Jose",
      "powers": ["Armor", "Flight", "Genius"]
    }
    """
    Given url baseUrl + '/testuser/api/characters/' + result.characterId
    And header Content-Type = 'application/json'
    And request requestBody
    When method put
    Then status 200
    And match response != null
    And match response.id == result.characterId
    And match response.name == 'Iron Man Updated'
    And match response.description == 'Updated description Jose'
    And match response.powers == ["Armor", "Flight", "Genius"]

    # Verificar la actualización consultando el personaje
    Given url baseUrl + '/testuser/api/characters/' + result.characterId
    When method get
    Then status 200
    And match response.name == 'Iron Man Updated'
    And match response.description == 'Updated description Jose'
    And match response.powers == ["Armor", "Flight", "Genius"]

  @id:5 @EliminarPersonaje
  Scenario: Eliminar un personaje por id
    # Crear el personaje
    * def newCharacterName = randomString(10)
    * def requestBody =
    """
    {
      "name": "#(newCharacterName)",
      "alterego": "Peter Parker",
      "description": "Personaje para eliminar",
      "powers": ["Web", "Agility", "Strength"]
    }
    """
    Given url baseUrl + '/testuser/api/characters'
    And header Content-Type = 'application/json'
    And request requestBody
    When method post
    Then status 201
    And match response != null
    And match response.id != null
    * def characterIdToDelete = response.id
    * print 'Personaje creado con ID:', characterIdToDelete

    # Eliminar el personaje
    * print 'Eliminando personaje con ID:', characterIdToDelete
    Given url baseUrl + '/testuser/api/characters/' + characterIdToDelete
    When method delete
    Then status 204

    # Verificar que el personaje fue eliminado
    Given url baseUrl + '/testuser/api/characters/' + characterIdToDelete
    When method get
    Then status 404
