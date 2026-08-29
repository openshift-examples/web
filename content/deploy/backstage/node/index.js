#!/usr/bin/env node

fetch('https://aap.coe.muc.redhat.com/api/v2/job_templates', {
    headers: {
      "Content-Type": "application/json",
      Authorization: 'YVkm5yVJttlh6RDeW9zZvhCNy7CTrg'
    },
    method: "GET"
  })
    .then((response) => response.text())
    .then((body) => {
        console.log(body);
    });

