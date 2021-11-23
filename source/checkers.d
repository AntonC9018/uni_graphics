module checkers;

import arsd.simpledisplay;
import common.bezier;
import common.util;
import std.stdio;
import std.algorithm;
import std.range;
import std.math;

v2 dimensions(in SimpleWindow window) { return v2(window.width, window.height); }
Point screenCenter(in SimpleWindow window) { return Point(window.width / 2, window.height / 2); }

void main()
{
	auto window = new SimpleWindow();
    auto cellWidth() { return min(window.width, window.height) / 8; }
    
    // Could store the checkers directly in the board, but whatever.
    enum eliminated = 1;
    enum colored = 2; // This info is already stored in the id, but whatever.
    enum queen = 4;

    int[4 * 3 * 2] checkers = 0;
    foreach (i; 0 .. 4 * 3)
        checkers[i] |= colored;

    int[8 * 8] board = -1;
    foreach (i; 0 .. 4 * 3)
    {
        int parity = (i / 4) & 1;
        board[i * 2 + parity] = i;
        board[8 * 8 - i * 2 - 1 - parity] = 4 * 6 - i - 1;
    }

    ref int idAt(Point pos)
    {
        return board[pos.x + pos.y * 8];
    }

    // Tested the no-go-backwards thing.
    // idAt(Point(1, 1)) = 0;
    // idAt(Point(6, 6)) = 1;
    // idAt(Point(4, 4)) = 4 * 3;
    // checkers[4 * 3] |= queen; 

    int selectedCheckerId = -1;
    Point selectedCheckerPosition;
    int ignoredDirectionIndex = -1;
    int playerTurn = 0;

    bool isGameRunning()
    {
        alias alive = a => !(a & eliminated);
        return checkers[0 .. 4 * 3].any!alive
            && checkers[4 * 3 .. $].any!alive;
    }

    // We use the same bit to check for black/white and up/down
    enum up = 2;
    static assert(up == colored);

    immutable Point[4] diagonalPositions = [
        Point(1, -1), Point(-1, -1), Point(-1, 1), Point(1, 1), ];
    
    struct Move
    {
        int directionIndex;
        Point direction() { return diagonalPositions[directionIndex]; }
        int swappedDirectionIndex() { return (directionIndex & 1) | (~directionIndex & up); }
        int amount = 1;
        Point offset() { return direction * amount; }
        bool take = false;
        bool valid = false;
    }

    bool checkInBounds(int x, int y)
    {
        return (x >= 0 && x < 8 && y < 8 && y >= 0);
    }

    bool belongsToCurrentPlayer(int checker)
    {
        return ((checker & colored) != 0) == (playerTurn == 1);
    }

    auto getCheckerMovesFromPosition(Point position, int checker, int ignoredDirectionIndex)
    {
        const isQueen = (checker & queen) != 0;

        return diagonalPositions[].enumerate.map!((t)
        {
            int index = cast(int) t.index; 
            Point diag = t.value;

            Move result;
            result.take = false;
            result.directionIndex = index;
            result.amount = 1;
            result.valid = false;

            if (ignoredDirectionIndex == index)
                return result;
            
            Point offsetPos = position + diag;
            
            if (!checkInBounds(offsetPos.tupleof))
                return result;

            bool validNotTaking = isQueen || ((index & up) == (checker & colored));

            // 1. Skip empty. Repeat if queen.
            // 2. Check if non-empty is ally. Done if yes.
            // 3. Check if space after non-empty is empty. 
            // 4. Repeat from start if queen.
            if (!isQueen && idAt(offsetPos) == -1)
            {
                result.valid = validNotTaking;
                return result;
            }
            
            // 4. Repeat if queen
            do
            {
                // 1. Skip empty. Repeat if queen
                while (isQueen)
                {
                    if (idAt(offsetPos) != -1)
                        break;
                        
                    offsetPos = offsetPos + diag;
                    result.valid = result.valid || validNotTaking;
                    
                    if (!checkInBounds(offsetPos.tupleof))
                        return result;

                    result.amount += 1;
                }

                // 3. Check if non-empty is ally
                const secondChecker = checkers[idAt(offsetPos)];
                // same color
                if ((secondChecker & colored) == (checker & colored))
                    return result;

                // 4. Check if space after enemy is empty. 
                offsetPos = offsetPos + diag;
                if (!checkInBounds(offsetPos.tupleof))
                    return result;

                const thirdCheckerId = idAt(offsetPos);
                if (thirdCheckerId != -1)
                    return result;

                result.amount += 1;
                result.take = true;
                result.valid = true;
            } 
            // Repeat if queen.
            while (isQueen);

            return result;

        }).filter!(r => r.valid);
    }

    bool areAnyTakeMoves()
    {
        if (ignoredDirectionIndex != -1)
            return true;
        foreach (i; iota(0, 8, 1))
        foreach (j; iota(0, 8, 1))
        {
            const p = Point(i, j);
            const id = idAt(p);
            if (id == -1)
                continue;
            const checker = checkers[id];
            if (belongsToCurrentPlayer(checker)
                && getCheckerMovesFromPosition(p, checker, -1).any!(p => p.take))
            {
                return true;
            }
        }
        return false;
    }

	window.eventLoop(1000/60,
	{	
		auto painter = window.draw();
		painter.clear();
		painter.outlineColor = Color.black;
		painter.fillColor = Color.black;

        if (!isGameRunning)
        {
            painter.drawText(Point(0, 0), "Game over");
            return;
        }

        void drawCell(int row, int col)
        {
            painter.drawRectangle(Point(col * cellWidth, row * cellWidth), cellWidth + 1, cellWidth + 1);
        }

        foreach (i; iota(0, 8, 1))
        foreach (j; iota(0, 8, 2))
        {
            painter.fillColor = Color(35, 35, 35);
            drawCell(j + (i & 1), i);

            painter.fillColor = Color(200, 200, 200);
            drawCell(j + (~i & 1), i);
        }

        if (selectedCheckerId != -1)
        {
            painter.fillColor = Color(0, 200, 355);
            int checker = checkers[selectedCheckerId];

            bool areTakes = areAnyTakeMoves();

            foreach (move; getCheckerMovesFromPosition(selectedCheckerPosition, checker, ignoredDirectionIndex))
            {
                if (areTakes && !move.take)
                    continue;
                int amount = 1;
                if (move.take)
                {
                    // Guaranteed to have an enemy in the way
                    while (idAt(move.direction * amount + selectedCheckerPosition) == -1)
                        amount++;
                }
                for(;amount <= move.amount; amount++)
                {
                    const pos = move.direction * amount + selectedCheckerPosition;
                    if (idAt(pos) == -1)
                        drawCell(pos.y, pos.x);
                }
            }
        }

        foreach (i; iota(0, 8, 1))
        foreach (j; iota(0, 8, 1))
        {
            const id = board[i * 8 + j];
            if (id != -1)
            {
                const checker = checkers[id];
                if (checker & eliminated)
                    continue;
                
                if (checker & colored)
                    painter.fillColor = Color.black;
                else
                    painter.fillColor = Color.white;
                
                enum leeway = 0.2;
                const leewayPixels = cast(int) (cellWidth * leeway);
                const pos = Point(j * cellWidth + leewayPixels, i * cellWidth + leewayPixels);
                const dim = cast(int) (cellWidth * (1 - leeway * 2));
                if (checker & queen)
                    painter.drawRectangle(pos, dim, dim);
                else
                    painter.drawCircle(pos, dim);
            }
        }

	}, delegate (MouseEvent ev) 
	{
		switch (ev.type)
		{
            case MouseEventType.buttonPressed:
            {
                if (ev.button == MouseButton.left)
                {
                    const coords = Point(ev.x / cellWidth, ev.y / cellWidth);
                    if (coords.x > 8 && coords.y > 8)
                        break;

                    if (selectedCheckerId == -1 ||
                    {
                        const targetOffset = coords - selectedCheckerPosition;
                        if (abs(targetOffset.x) != abs(targetOffset.y))
                            return true;
                        int sign(int x) { return x > 0 ? 1 : -1; }
                        const diag = Point(sign(targetOffset.x), sign(targetOffset.y));

                        // Is a diagonal direction
                        foreach (move; getCheckerMovesFromPosition(selectedCheckerPosition, checkers[selectedCheckerId], ignoredDirectionIndex))
                        {
                            if (move.direction != diag)
                                continue;

                            if (abs(targetOffset.x) > move.amount)
                                continue;

                            // do move
                            bool took;
                            if (move.take)
                            {
                                foreach (int amount; 1 .. abs(targetOffset.x))
                                {
                                    const p = diag * amount + selectedCheckerPosition;
                                    if (idAt(p) != -1)
                                    {
                                        checkers[idAt(p)] |= eliminated;
                                        idAt(p) = -1;
                                        took = true;
                                    }
                                }
                            }
                            
                            if (!took && areAnyTakeMoves())
                                return false;

                            idAt(coords) = selectedCheckerId;
                            idAt(selectedCheckerPosition) = -1;
                            selectedCheckerPosition = coords;
                            ignoredDirectionIndex = -1;

                            if ((coords.y == 7 && (checkers[selectedCheckerId] & colored))
                                || (coords.y == 0 && (~checkers[selectedCheckerId] & colored)))
                            {
                                checkers[selectedCheckerId] |= queen;
                            }
                            
                            if (!took || !getCheckerMovesFromPosition(selectedCheckerPosition, checkers[selectedCheckerId], move.swappedDirectionIndex)
                                .any!(m => m.take))
                            {
                                selectedCheckerId = -1;
                                ignoredDirectionIndex = move.swappedDirectionIndex;
                                playerTurn = 1 - playerTurn;
                                return false;
                            }
                            if (ignoredDirectionIndex != -1)
                                return false;
                        }
                        return true;
                    }())
                    {
                        const id = board[coords.x + coords.y * 8];
                        if (id == -1)
                            break;

                        const checker = checkers[id];
                        if (belongsToCurrentPlayer(checker))
                        {
                            selectedCheckerId = id;
                            selectedCheckerPosition = coords;
                            ignoredDirectionIndex = -1;
                        }
                    }
                }
                break;
            }
			default: return;
		}
	});
}
