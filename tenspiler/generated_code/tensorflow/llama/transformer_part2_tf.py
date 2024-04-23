
####### import statements ########
import tensorflow as tf

def transformer_part2_tf(token_position, head, head_size, key_cache_layer, attention):
    return tf.linalg.matvec(tf.transpose(key_cache_layer[:(token_position) + (1)][:, (head) * (head_size):(head) * (head_size) + head_size]), attention[:(token_position) + (1)])

def transformer_part2_tf_glued(token_position, head, head_size, key_cache_layer, attention):
    key_cache_layer = tf.convert_to_tensor(key_cache_layer, dtype=tf.float32)
    attention = tf.convert_to_tensor(attention, dtype=tf.float32)
    return transformer_part2_tf(token_position, head, head_size, key_cache_layer, attention)