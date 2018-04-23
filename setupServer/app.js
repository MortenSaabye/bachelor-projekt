var express = require("express")
var wifi = require("node-wifi")
var bodyParser = require("body-parser")

var app = express()
const PORT = 3000
const INTERFACE = 'en0'

app.use(bodyParser.json())


app.get('/getwifiinfo', (req, res) => {
    wifi.init({iface: INTERFACE})

    wifi.scan((err, networks) =>  {
        if(err) {
            res.statusCode = 500
        } else {
            res.statusCode = 200
        }
        res.json({resultData: networks, errormessage: err})
    })
})

app.post('/connect', (req, res) => {
    wifi.connect({ ssid : req.body.ssid, password : req.body.passcode}, (err) => {
        let success = true
        if (err) {
            success = false
        }
        res.json({success: success, errormessage: err});
    });
})
 
app.listen(PORT, () => {
    console.log(`Listening on ${PORT}`)
})