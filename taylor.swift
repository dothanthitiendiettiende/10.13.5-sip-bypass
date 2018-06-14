import Foundation

print("sleep")

// infinite loop that won't produce warning
while Date().timeIntervalSince1970 > 0 {
    usleep(1000000)
}

print("bye, cruel world")
