import React, {Component} from 'react';


export class Ingred extends Component {

    state = {
        ingredients: []
      };
    
    componentDidMount() {
     this.getIngredients();
    }
    
    getIngredients = _ => {
      fetch('http://localhost:4000/recipes/view?name=scrambled_eggs')
      .then(response => response.json() )
      .then (response => this.setState({ingredients: response.data}))
      .catch(err => console.error(err))
    }
    
    
    renderIngredients = ({recipeName, instructions
                        ,difficulty,servings,CalsPerServing,FatPerServing
                        ,CarbsPerServing,ProteinPerServing,recipeRating}) => 
                  <div key={recipeName}>
                    {instructions + " " } 
                    {difficulty + " " }
                    {servings }
                    {CalsPerServing}
                    {FatPerServing}
                    {CarbsPerServing}
                    {ProteinPerServing}
                    {recipeRating}
                  </div>

  render() {
    const {ingredients} = this.state;
    return (
        <div class = "prod_container">
          <div class = "prod_name">
          <div><h1>Ingredients</h1></div>
            <h2 onClick={this.titleWasClicked}>
              <div>{ingredients.map(this.renderIngredients)}</div>
            </h2>
          </div>
        </div>
    );
  }  
}