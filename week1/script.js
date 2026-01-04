// Counter variable
let counter = 0;

// Function to update text
function updateText() {
    const messages = [
        "You clicked the button! 🎉",
        "This text keeps changing!",
        "JavaScript is fun! 💻",
        "Keep clicking to see more messages!",
        "You're doing great! 🌟"
    ];
    const randomMessage = messages[Math.floor(Math.random() * messages.length)];
    document.getElementById('changingText').textContent = randomMessage;
}

// Function to show greeting
function showGreeting() {
    const name = document.getElementById('nameInput').value;
    const output = document.getElementById('greetingOutput');
    
    if (name.trim() === '') {
        output.textContent = 'Please enter your name!';
    } else {
        output.textContent = `Hello, ${name}! Welcome to my portfolio! 👋`;
    }
}

// Function to increase counter
function increaseCounter() {
    counter++;
    document.getElementById('counterDisplay').textContent = counter;
}

// Function to decrease counter
function decreaseCounter() {
    counter--;
    document.getElementById('counterDisplay').textContent = counter;
}

// Function to reset counter
function resetCounter() {
    counter = 0;
    document.getElementById('counterDisplay').textContent = counter;
}

// Function to toggle theme
function toggleTheme() {
    document.body.classList.toggle('dark-theme');
}