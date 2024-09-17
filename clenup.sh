#!/bin/bash

docker stop jenkins

docker rm jenkins

docker rmi shaun/jenkins:1.0.0