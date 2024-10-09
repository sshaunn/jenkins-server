#!bin/bash
check_success() {
  if [ $? -ne 0 ]; then
      echo "Error: $1"
      exit 1
  fi
}

./cleanup.sh
check_success "Failed clean up docker containers..."

# If cleanup is successful, attempt to run start.sh with retries
    max_attempts=3
    attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts: Running start.sh"
        ./start.sh

        if [ $? -eq 0 ]; then
            echo "start.sh executed successfully"
            exit 0
        else
            echo "start.sh failed on attempt $attempt"
            if [ $attempt -eq $max_attempts ]; then
                echo "Maximum retry attempts reached. Exiting."
                exit 1
            fi
            # Wait for 5 seconds before the next attempt
            sleep 5
        fi

        ((attempt++))
    done
else
    echo "cleanup.sh failed. Exiting without running start.sh"
    exit 1
fi