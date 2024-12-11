#!/usr/bin/env node

const fs = require("fs");

const file = process.argv[2];

const contents = fs.readFileSync(file, "utf8");

let disk = [];
let is_free_space = false;
let id = 0;

for (let i = 0; i < contents.length; i++) {
  const char = contents[i];
  const len = +char;

  if (is_free_space) {
    for (let j = 0; j < len; j++) {
      disk.push(null);
    }
  } else {
    for (let j = 0; j < len; j++) {
      disk.push(id);
    }
    id++;
  }

  is_free_space = !is_free_space;
}

let i = 0;
let j = disk.length - 1;
let sum = 0;
while (i < disk.length) {
  if (i <= j && disk[i] === null) {
    while (disk[j] === null) {
      j--;
    }

    disk[i] = disk[j];
    disk[j] = null;
    j--;
  }

  if (disk[i] !== null) {
    sum += +disk[i] * i;
  }

  i++;
}

console.log(sum);
