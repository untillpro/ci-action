#!/bin/bash

echo "making build airs-bp3"
  go build -o airs-bp airsbp3/cli/*.go
echo "rebuild baseline schemas"
  ./airs-bp baseline_schemas airsbp3/baseline_schemas
