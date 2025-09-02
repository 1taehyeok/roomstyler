#!/bin/bash
# test_runner.sh
# Script to run all tests with coverage

echo "Running all tests with coverage..."
flutter test --coverage

echo "Generating coverage report..."
genhtml coverage/lcov.info -o coverage/html

echo "Coverage report generated at coverage/html/index.html"