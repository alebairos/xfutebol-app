import './Board.css';
import Tile from '../Tile/Tile'; // Import the 'Tile' component

const horizontalAxis = ["a", "b", "c", "d", "e", "f", "g", "h"];
const verticalAxis = ["1", "2", "3", "4", "5", "6", "7", "8"];

interface Piece{
    image: string;
    x: number;
    y: number;
}
const pieces: Piece[] = [];
        for (let i = 0; i < 8; i++) {
            pieces.push({image: "assets/images/pawn_b.png", x: i, y: 6});
        }

        for (let i = 0; i < 8; i++) {
            pieces.push({image: "assets/images/pawn_w.png", x: i, y: 1});
        }

        //rook
        pieces.push({image: "assets/images/rook_b.png", x: 0, y: 7});
        pieces.push({image: "assets/images/rook_b.png", x: 7, y: 7});

        //rook white
        pieces.push({image: "assets/images/rook_w.png", x: 0, y: 0});
        pieces.push({image: "assets/images/rook_w.png", x: 7, y: 0});

        //bishop
        pieces.push({image: "assets/images/bishop_w.png", x: 2, y: 7});
        pieces.push({image: "assets/images/bishop_w.png", x: 5, y: 7});

        //bishop white
        pieces.push({image: "assets/images/bishop_b.png", x: 2, y: 0});
        pieces.push({image: "assets/images/bishop_b.png", x: 5, y: 0});

        //knight black
        pieces.push({image: "assets/images/knight_b.png", x: 1, y: 7});
        pieces.push({image: "assets/images/knight_b.png", x: 6, y: 7});

        //knight white
        pieces.push({image: "assets/images/knight_w.png", x: 1, y: 0});
        pieces.push({image: "assets/images/knight_w.png", x: 6, y: 0});

        //queen
        pieces.push({image: "assets/images/queen_b.png", x: 3, y: 7});
        //queen white
        pieces.push({image: "assets/images/queen_w.png", x: 3, y: 0});

        //king
        pieces.push({image: "assets/images/king_b.png", x: 4, y: 7});
        //king white
        pieces.push({image: "assets/images/king_w.png", x: 4, y: 0});
        
    //grab piece react mouse event
function grabPiece(e: React.MouseEvent<HTMLDivElement, MouseEvent>) {
    let elem = e.target as HTMLDivElement;
    //log
    console.log(elem);
    if (elem.classList.contains("board-piece")) {
        //log
        console.log("grabbed");
        elem.style.position = "absolute";
        elem.style.zIndex = "1000";

        const chessboard = document.getElementById("board");
        if (!chessboard) {
            //log
            console.log("chessboard not found");
            return;
        };
        const rect = chessboard.getBoundingClientRect();
        const tileSize = rect.width / 8; // Assuming an 8x8 chessboard

        // Store the original position of the piece
        const originalPosition = { left: elem.style.left, top: elem.style.top }; 

        document.onmousemove = function (e) {
            let left = e.pageX - rect.left - elem.offsetWidth / 2;
            let top = e.pageY - rect.top - elem.offsetHeight / 2;

            // Ensure the piece stays within the bounds of the chessboard
            left = Math.max(0, Math.min(left, rect.width - elem.offsetWidth));
            top = Math.max(0, Math.min(top, rect.height - elem.offsetHeight));

            elem.style.left = left + "px";
            elem.style.top = top + "px";

        };


        elem.onmouseup = function () {
            document.onmousemove = null;
            elem.onmouseup = null;

            // Calculate the tile coordinates and move the piece there
            const tileX = Math.round(parseInt(elem.style.left) / tileSize);
            const tileY = Math.round(parseInt(elem.style.top) / tileSize);

                        // Check if the move is legal
            if (!isLegalMove(tileX, tileY)) {
                // If the move is not legal, move the piece back to its original position
                                elem.style.left = originalPosition.left;
                elem.style.top = originalPosition.top;
            } else {
                // If the move is legal, move the piece to the new position
                                elem.style.left = tileX * tileSize + "px";
                elem.style.top = tileY * tileSize + "px";
            }

        };
    }
}

// This is a placeholder function. You should replace it with your own logic to check if a move is legal.
function isLegalMove(x: number, y: number) {
    // Replace this with your own logic
  
    return true;
} 

export default function Board() {
    let board = [];
    for (let j = verticalAxis.length - 1; j >= 0; j--) {
      for (let i = 0; i < horizontalAxis.length; i++) {
        const number = i + j + 2;
        let image = undefined;
        pieces.forEach((p) => {
          if (p.x === i && p.y === j) {
            image = p.image;
          }
        });
        let key = j.toString() + i.toString();
        board.push(
          <Tile
            key={key}
            image={image}
            number={number}
            rank={horizontalAxis[i]}
            file={verticalAxis[j]}
          />
        );
      }
    }
  
    return <div onMouseDown={e => grabPiece(e)} id="board">{board}</div>;
  }