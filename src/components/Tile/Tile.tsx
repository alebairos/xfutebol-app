import React from 'react';
import './Tile.css';

interface Props {
    number: number;
    image?: string;
    rank: string;
    file: string;
}

export default function Tile({ number, image, rank, file }: Props) {
    let imgelem = image ? (
        <div className="board-piece" style={{ backgroundImage: `url(${image})` }}></div>
    ) : (
        ''
    );

    return (
        <div className={number % 2 === 0 ? 'tile black-tile' : 'tile white-tile'}>
            <div className="rank-file">{`${rank}${file}`}</div>
            {imgelem}
        </div>
    );
}