# Tic-Tac-Toe in PL/pgSQL

This project is a simple implementation of the Tic-Tac-Toe game written entirely in PL/pgSQL. It uses two functions to create and update the game state directly inside the database. Each function call returns the current 3×3 board or the final game result, making it possible to play the whole game through SQL queries.

## Task-imposed implementation constraints

This project was originally written as a student assignment, and several task constraints dictated how the implementation had to be structured:

- each board cell had to be stored as a separate table row  
- arrays, strings, and other compact board formats were not allowed  
- the program had to expose exactly two public functions (NewGame and NextMove)  
- the symbol for each move had to be determined automatically because the game alternates turns  

Because of these requirements, the game state is stored in temporary tables inside the database session rather than using a more typical or compact representation.

## How it works

The game stores its state in two temporary tables: one for the board cells and one for the game status. NewGame resets everything and returns an empty 3×3 board. NextMove checks whether the move is valid, places the symbol, switches the player, and checks for a win or a tie. The helper function getBoard simply returns the current board in a readable 3×3 format (e.g. to peek at the board after the game is over).

## How to use

To start a new game, call NewGame. Each move is made by calling NextMove with the desired coordinates. If you want to view the board independently of making a move, you can also call getBoard.

Examples:

```sql
SELECT * FROM NewGame();
SELECT * FROM NextMove(1, 2);
SELECT * FROM getBoard();
```

## Limitations

Only one game can run per database session.

