import React, {Component} from 'react';
import './App.css';

import {Recipes} from './components/Recipes'


function App(){
  return(
    <div className = "container">
      <Recipes/>
    </div>
  );
}

export default App;