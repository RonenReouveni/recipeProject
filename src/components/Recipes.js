import React, {Component} from 'react';
import '../App.css';

export class Recipes extends Component {

  state = {
    recipes: []
  };
componentDidMount() {
 this.getRecipes();

}
getRecipes = _ => {
  fetch('http://localhost:4000/recipes')
  .then(response => response.json() )
  .then (response => this.setState({recipes: response.data}))
  .catch(err => console.error(err))
}
  render() {
    const {recipes} = this.state;
    return (
          <div >
          <div class="test"><h1>Recipes</h1></div>
            {recipes.map((postDetail, index) =>{
              return <div class= "container">
                <div class="name">{postDetail.recipeName}</div>              
                <div class="threeCol">
                  <div class="colThree">Difficulty: {postDetail.difficulty}</div>
                  <div class="colThree">Rating: {postDetail.recipeRating}</div>
                  <div class="colThree">Servings: {postDetail.servings}</div>
                </div>
                <div class="pic"><img src={postDetail.recPhoto}/></div>
                <div class="twoCol">
                      <div class="oneThirdCol">
                      <div class="ingredientTitle">Ingredients</div>
                            <div class="text">{postDetail.ingredients.replace(/each/g,"").split(",").map(place => <li> {place} </li>) }</div>
                      </div>
                      <div class="threeQuartersCol">                            
                            <div class="intructionTitle">Instructions</div>
                            <div class="text"><p>{postDetail.instructions.split("!").map(place => <p> {place} </p>)}</p></div>
                      </div>
                </div>
              <div class="twoCol">
                    <div class="threeQuartersCol">
                        <div class="nutritionTitle">Nutrition Facts Per Serving:</div>
                        <div>{postDetail.CalsPerServing} Calories, {postDetail.FatPerServing}gs Fat, {postDetail.CarbsPerServing}gs Carbs, {postDetail.ProteinPerServing}gs Protein</div>
                    </div>

                    <div class="oneThirdCol">
                        <div class="nutritionTitle">Tags</div>
                        {postDetail.tags.split(",").join(", ") }
                    </div>
              </div>

               </div>
            })}
          </div>
    );
  }  
}