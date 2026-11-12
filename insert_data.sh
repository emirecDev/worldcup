#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.
# Limpiar las tablas y reiniciar los contadores SERIAL antes de empezar
echo $($PSQL "TRUNCATE games, teams RESTART IDENTITY;")

# Leer el archivo usando la coma como separador correcto (IFS=',')
cat games.csv | while IFS=',' read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # Filtrar estrictamente la cabecera ignorando la palabra 'year' o 'winner'
  if [[ $YEAR != "year" && ! -z $YEAR ]]
  then
    # ==========================================
    # 1. PROCESAR EQUIPO GANADOR (WINNER)
    # ==========================================
    WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER';")
    
    if [[ -z $WINNER_ID ]]
    then
      INSERT_WINNER_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$WINNER');")
      if [[ $INSERT_WINNER_RESULT == "INSERT 0 1" ]]
      then
        echo "Inserted team: $WINNER"
      fi
      # Recuperar el ID recién creado
      WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER';")
    fi

    # ==========================================
    # 2. PROCESAR EQUIPO OPONENTE (OPPONENT)
    # ==========================================
    OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT';")
    
    if [[ -z $OPPONENT_ID ]]
    then
      INSERT_OPPONENT_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$OPPONENT');")
      if [[ $INSERT_OPPONENT_RESULT == "INSERT 0 1" ]]
      then
        echo "Inserted team: $OPPONENT"
      fi
      # Recuperar el ID recién creado
      OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT';")
    fi

    # ==========================================
    # 3. INSERTAR EL PARTIDO (GAME)
    # ==========================================
    # Pasamos las variables numéricas y de texto con comillas simples en SQL para evitar errores de sintaxis
    INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS);")
    
    if [[ $INSERT_GAME_RESULT == "INSERT 0 1" ]]
    then
      echo "Inserted game: $YEAR $ROUND - $WINNER vs $OPPONENT"
    fi
  fi
done
