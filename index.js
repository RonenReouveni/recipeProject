const express = require('express');
const cors = require('cors');
const mysql = require('mysql')

const app = express();



const SELECT_REC_LIST = 'SELECT * FROM recList'


const connection = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '******',
    database: 'recDB'
});

connection.connect(err => {
    if(err) {
        return err;
    }
});


app.use(cors());

app.get('/', (req, res) => {
    res.send('go to /recipe to see recipes')
})





app.get('/recipes', (req, res) => {
    connection.query(SELECT_REC_LIST, (err, results) => {
        if(err) {
            return res.send(err)
        }
        else {
            return res.json({
                data: results
            })
        }
    });
});



app.listen(4000, () => {
    console.log('My server is listening on port 4000')
});

