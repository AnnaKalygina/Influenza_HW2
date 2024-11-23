#!/bin/bash

mean_60=$(awk '/Mean Frequency of control 60:/ {print $5}' control_statistics.txt)
stddev_60=$(awk '/Standard Deviation of control 60:/ {print $5}' control_statistics.txt)

mean_59=$(awk '/Mean Frequency of control 59:/ {print $5}' control_statistics.txt)
stddev_59=$(awk '/Standard Deviation of control 59:/ {print $5}' control_statistics.txt)

mean_58=$(awk '/Mean Frequency of control 58:/ {print $5}' control_statistics.txt)
stddev_58=$(awk '/Standard Deviation of control 58:/ {print $5}' control_statistics.txt)

awk -v mean_60="$mean_60" -v stddev_60="$stddev_60" \
    -v mean_59="$mean_59" -v stddev_59="$stddev_59" \
    -v mean_58="$mean_58" -v stddev_58="$stddev_58" \
    '{
    # Extract frequency and convert it to a decimal
    freq = $6; sub("%", "", freq); freq = freq / 100;

    # Calculate thresholds for each control
    threshold_60 = mean_60 + 3 * stddev_60;
    threshold_59 = mean_59 + 3 * stddev_59;
    threshold_58 = mean_58 + 3 * stddev_58;

    # Check if the frequency is greater than the thresholds
    if (freq > threshold_60 || freq > threshold_59 || freq > threshold_58) {
        print "Significant variant at position", $2, "with frequency", $6
    }
}' ../rare_variants_summary.txt > ../significant_variants_roommate.txt
