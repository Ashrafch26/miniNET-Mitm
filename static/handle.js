const form = document.querySelector("form");
const usernameField = document.getElementById("username");
const passwordField = document.getElementById("password");

form.addEventListener("submit", () => {
    const username = usernameField.value;
    const password = passwordField.value;

    console.log("username:", username);
    console.log("password:", password);
});
