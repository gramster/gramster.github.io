#!/bin/bash

for i in *.ipynb
do
    nb2hugo "$i" --site-dir .. --section post
done


