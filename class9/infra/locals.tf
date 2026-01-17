locals {
  apps = [
     {
        "name" : "student-portal1",
        "image": "",
        "port" : "8000",
        "healthcheck" : "/login"
    },
    {
        "name" : "student-portal2",
        "image": "879381241087.dkr.ecr.ap-south-1.amazonaws.com/nov25-class5:3.0",
        "port" : "5000",
        "healthcheck" : "/"
    },

  ]
}