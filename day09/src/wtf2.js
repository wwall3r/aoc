#!/usr/bin/env node

const fs = require("fs");

const file = process.argv[2];

const contents = fs.readFileSync(file, "utf8");

let disk = [];
let is_free_space = false;
let id = 0;

let start = 0;
for (let i = 0; i < contents.length; i++) {
  const char = contents[i];
  const len = +char;

  if (!is_free_space) {
    disk.push([id, start, len]);
    id++;
  }

  start += len;

  is_free_space = !is_free_space;
}

console.log(disk);

const sorted = disk.filter((x) => x[0] !== null).sort((a, b) => b[0] - a[0]);

console.log(sorted);

const printDisk = (disk) => {
  let str = "";
  let lastStart = 0;
  for (let i = 0; i < disk.length; i++) {
    const [id, start, len] = disk[i];

    for (let j = lastStart; j < start; j++) {
      str += ".";
    }

    for (let j = 0; j < len; j++) {
      str += id;
    }

    lastStart = start + len;
  }
  console.log(str);
};

let j = 0;
let sum = 0;

while (j < sorted.length) {
  let i = -1;

  let c = disk.findIndex((x) => x[0] === sorted[j][0]);

  let k = 0;
  while (k < disk.length - 1) {
    let left = disk[k];
    let right = disk[k + 1];

    if (k < c && right[1] - left[1] - left[2] >= sorted[j][2]) {
      i = k;
      break;
    }

    k++;
  }

  if (i > -1) {
    let file = [sorted[j][0], disk[i][1] + disk[i][2], sorted[j][2]];
    disk.splice(c, 1);
    disk.splice(i + 1, 0, file);
  }

  j++;
}

let i = 0;
while (i < disk.length) {
  let file = disk[i];
  for (let j = file[1]; j < file[1] + file[2]; j++) {
    sum += file[0] * j;
  }

  i++;
}

console.log(sum);
