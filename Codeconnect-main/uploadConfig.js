const fs = require("fs");
const { execSync } = require("child_process");

const env = fs.readFileSync(".env", "utf-8");
env.split("\n").forEach((line) => {
  const [key, value] = line.split("=");
  if (key && value) {
    const path = key.toLowerCase().replace(/_/g, "."); // example: DB_PASSWORD => db.password
    const command = `firebase functions:config:set ${path}="${value.trim()}"`;
    execSync(command, { stdio: "inherit" });
  }
});
