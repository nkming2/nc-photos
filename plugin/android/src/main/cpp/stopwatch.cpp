#include "stopwatch.h"
#include <chrono>

using namespace std;

Stopwatch::Stopwatch()
    : is_start_(true), beg_(chrono::steady_clock::now()),
      time_elapsed_(chrono::steady_clock::duration::zero()),
      offset_(chrono::steady_clock::duration::zero()) {}

void Stopwatch::resume() {
  if (!is_start_) {
    beg_ = chrono::steady_clock::now();
    is_start_ = true;
  }
}

void Stopwatch::pause() {
  if (is_start_) {
    time_elapsed_ += chrono::steady_clock::now() - beg_;
    is_start_ = false;
  }
}

chrono::steady_clock::duration Stopwatch::getTime() const {
  if (is_start_) {
    return time_elapsed_ + offset_ + (chrono::steady_clock::now() - beg_);
  } else {
    return time_elapsed_ + offset_;
  }
}

void Stopwatch::resetClock() {
  time_elapsed_ = chrono::steady_clock::duration::zero();
  offset_ = chrono::steady_clock::duration::zero();
}
