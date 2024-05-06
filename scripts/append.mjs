import fs from "fs";

export const appendToEnv = (key, value) => {
  fs.appendFileSync(".env", `\n${key}=${value}\n`);
};
