from flask import Flask, request

USERNAME = "admin"
PASSWORD = "admin"

app = Flask(__name__)

@app.route("/")
def home():
    return "<h1>welcome to the hood</h1>"

@app.route("/login", methods = ["POST"])
def login():
    username = request.form.get('username')
    password = request.form.get('password')
    if username == USERNAME and password == PASSWORD:
        return "success"
    else:
        return "failer"

if __name__=="__main__":
    app.run("0.0.0.0",80,True) # wee can use here another address and it"s depend on the network addressing
