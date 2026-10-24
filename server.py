from flask import Flask, request, render_template

USERNAME = "admin"
PASSWORD = "admin"

app = Flask(__name__, static_folder="./static/")

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/login", methods = ["POST"])
def login():
    username = request.form.get('username')
    password = request.form.get('password')
    success = username == USERNAME and password == PASSWORD
    return render_template("result.html", success=success)

if __name__=="__main__":
    app.run("0.0.0.0",5000,True) # wee can use here another address and it"s depend on the network addressing
