#!/bin/bash

for i in notebooks/*.ipynb;do;nb2hugo "$i" --site-dir . --section post;done

