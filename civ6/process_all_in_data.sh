#!/bin/bash

IFS=$(echo -en "\n\b"); rm consolidated.csv; for x in $(find data/*.json ); do ruby timeline_to_csv.rb "$x" >> consolidated.csv; done
