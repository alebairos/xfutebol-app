import React from 'react';
import './Tile.css';

interface Props{
    number: number;
    image?: string;
}
export default function Tile({number, image}: Props) {
    let  imgelem = undefined
    imgelem = image ? <div className="board-piece" style={{backgroundImage: `url(${image})`}}></div> : '';
    if (number % 2 === 0) {
        return (<div className='tile black-tile'>
        {imgelem}
        </div>);
    }
    else {
        return (<div className='tile white-tile'>
        {imgelem}
        </div>);
    }
}