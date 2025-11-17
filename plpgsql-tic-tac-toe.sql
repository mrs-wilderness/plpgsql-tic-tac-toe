
CREATE OR REPLACE FUNCTION NewGame()
RETURNS TABLE(i varchar(6), ii varchar(6), iii varchar(6))
LANGUAGE plpgsql
AS $$
BEGIN
	DROP TABLE IF EXISTS state;
	DROP TABLE IF EXISTS status;
	
	CREATE TEMP TABLE state
	(
		X INT NOT NULL,
		Y INT NOT NULL,
		val_at_xy char(1) DEFAULT NULL
	);

	CREATE TEMP TABLE status
	(
		is_X boolean NOT NULL,
		has_winner boolean NOT NULL
	);

	--populate the state table with all the possible combos of coordinates
	INSERT INTO state(X, Y)
	VALUES(1, 1), (1, 2), (1, 3), (2, 1), (2, 2), (2, 3), (3, 1), (3, 2), (3, 3);
	
	--set the current player to X(is_X = True) and has_winner to False
	INSERT INTO status VALUES(TRUE, FALSE);

	RAISE NOTICE 'SYNTAX: NextMove(row, col)';

	--return an empty board
	RETURN QUERY
	SELECT ' '::varchar(6) AS i, ' '::varchar(6) AS ii, ' '::varchar(6) AS iii
	FROM state
	GROUP BY X
	ORDER BY X;
	
END;
$$;


CREATE OR REPLACE FUNCTION NextMove(row_X INT, col_Y INT)
RETURNS TABLE(i VARCHAR(6), ii VARCHAR(6), iii VARCHAR(6))
LANGUAGE plpgsql
AS $$
DECLARE
    curr VARCHAR(6); --current player('X'/'O')
	move_count INT; --number of moves made
BEGIN
    -- check if the game is over
    IF (SELECT has_winner FROM status) THEN
        RAISE EXCEPTION 'This game is already over.';
    END IF;
    
    -- check if the coordinates are valid
    IF row_X NOT BETWEEN 1 AND 3 OR col_Y NOT BETWEEN 1 AND 3 THEN
        RAISE NOTICE 'Invalid move: (%, %) is out of bounds.', row_X, col_Y;
		RETURN QUERY
        SELECT * from getBoard();
	RETURN;
    END IF;
	
	--check if the coordinates are available
    IF (SELECT val_at_xy FROM state WHERE X = row_X AND Y = col_Y) IS NOT NULL THEN
        RAISE NOTICE 'Invalid move: (%, %) is already occupied.', row_X, col_Y;
		RETURN QUERY
        SELECT * from getBoard();
	RETURN;
    END IF;
    
    -- determine the current player for the move
    IF (SELECT is_X FROM status) THEN
        curr := 'X';
    ELSE
        curr := 'O';
    END IF;

    -- switch the player for the next move
    UPDATE status SET is_X = NOT is_X;
    
    -- make the move
    UPDATE state SET val_at_xy = curr WHERE X = row_X AND Y = col_Y;

	--count total moves so far
	SELECT COUNT(*) INTO move_count FROM state WHERE val_at_xy IS NOT NULL;

    -- WINNER CHECKS when enough moves were made
	IF move_count > 4 THEN
		-- check for the row where the move was made
	    IF (SELECT COUNT(*) FROM state 
	        WHERE X = row_X
				AND val_at_xy = curr) = 3 OR
	    -- check for the column where the move was made
	    (SELECT COUNT(*) FROM state 
	        WHERE Y = col_Y
				AND val_at_xy = curr) = 3 OR
	    -- check for 1,1 -> 3,3 diagonal
	    (row_X = col_Y AND
			(SELECT COUNT(*) FROM state 
	        	WHERE X = Y
					AND val_at_xy = curr) = 3) OR
	    -- check for 1,3 -> 3,1 diagonal
	    ((row_X + col_Y = 4) AND
			(SELECT COUNT(*) FROM state 
	        	WHERE (X + Y = 4)
					AND val_at_xy = curr) = 3) THEN
	        UPDATE status SET has_winner = TRUE;
	    END IF;
	END IF;

    -- return the result if the game is over
    IF (SELECT has_winner FROM status) THEN
        RETURN QUERY
        SELECT 'Player'::VARCHAR(6), curr::VARCHAR(6), 'wins!'::VARCHAR(6);
    ELSIF move_count = 9 THEN
        RETURN QUERY
        SELECT 'It is'::VARCHAR(6), 'a'::VARCHAR(6), 'tie.'::VARCHAR(6);
    -- return the current state of the game board if it's not over
	ELSE
        RETURN QUERY
        SELECT * from getBoard();
    END IF;
END;
$$;

--helper function to get the current state of the board
CREATE OR REPLACE FUNCTION getBoard()
RETURNS TABLE(i VARCHAR(6), ii VARCHAR(6), iii VARCHAR(6))
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	   SELECT 
		   COALESCE(MAX(CASE WHEN Y = 1 THEN val_at_xy END), ' ')::VARCHAR(6) AS i,
		   COALESCE(MAX(CASE WHEN Y = 2 THEN val_at_xy END), ' ')::VARCHAR(6) AS ii,
		   COALESCE(MAX(CASE WHEN Y = 3 THEN val_at_xy END), ' ')::VARCHAR(6) AS iii
	   FROM state
	   GROUP BY X
	   ORDER BY X;
END;
$$;

-- Example usage:

-- Start a new game:
-- SELECT * FROM NewGame();
-- Make a move:
-- SELECT * FROM NextMove(1,2);

-- View the board without making a move:
-- SELECT * FROM getBoard();