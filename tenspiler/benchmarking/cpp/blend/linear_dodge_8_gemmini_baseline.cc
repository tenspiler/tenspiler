#include <iostream>
#include <vector>
#include <chrono>
#include <stdio.h>
#include <stdlib.h>

#include "utils.h"

using namespace std;
using namespace std::chrono;

std::chrono::time_point<std::chrono::high_resolution_clock> start_time_k;
std::chrono::time_point<std::chrono::high_resolution_clock> end_time_k;

vector<vector<uint8_t>> linear_dodge_8(vector<vector<uint8_t>> base, vector<vector<uint8_t>> active) {
    start_time_k = high_resolution_clock::now();
    vector<vector<uint8_t>> out;
    int m = base.size();
    int n = base[0].size();
    for (int row = 0; row < m; row++) {
        vector<uint8_t> row_vec;
        for (int col = 0; col < n; col++) {
            uint8_t pixel = base[row][col] + active[row][col];
            row_vec.push_back(pixel);
        }
        out.push_back(row_vec);
    }
    end_time_k = high_resolution_clock::now();
    return out;
}

int main() {
    srand(1);

    vector<long long> times;
    vector<long long> times_k;
    size_t count = 10000;
    for (int i = 0; i < 10; i++) {
        long long time = 0;
        long long time_k = 0;
        for (int j = 0; j < count; j++) {
            vector<vector<uint8_t>> base = random_matrix_grayscale(500, 500); 
            vector<vector<uint8_t>> active = random_matrix_grayscale(500, 500); 

            auto start_time = high_resolution_clock::now();
            linear_dodge_8(base, active);
            auto end_time = high_resolution_clock::now();

            time += duration_cast<microseconds>(end_time - start_time).count();
            time_k += duration_cast<microseconds>(end_time_k - start_time_k).count();
        }
        times.push_back(time);
        times_k.push_back(time_k);
    }

    cout << "linear_dodge_8_gemmini_baseline" << endl;
    cout << average(times) / 1000.0 << " " << stdiv(times) / 1000.0 << endl;
    cout << average(times_k) / 1000.0 << " " << stdiv(times_k) / 1000.0 << endl;
    return 0;
}