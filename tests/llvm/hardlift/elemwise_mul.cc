#include <vector>
using namespace std;

vector<int> elemwise_mul(vector<int> input1, vector<int> input2, int hidden_dim) {
    vector<int> output;
    for (int i = 0; i < hidden_dim; i++) {
        output.push_back(input1[i] * input2[i]);
    }
    return output;
}
// def elemwise_mul_ps(input1 input2 hidden_dim elemwise_mul_rv)
// elemwise_mul_rv == vec_elemwise_mul(list_take(input2, hidden_dim), list_take(input1, hidden_dim))