#include <chrono>

#include "stopwatch.h"

using namespace std;

namespace np_torch {

Stopwatch::Stopwatch()
    : isStart_(true), beg_(chrono::steady_clock::now()),
      timeElapsed_(chrono::steady_clock::duration::zero()),
      offset_(chrono::steady_clock::duration::zero()) {}

void Stopwatch::resume() {
  if (!isStart_) {
    beg_ = chrono::steady_clock::now();
    isStart_ = true;
  }
}

void Stopwatch::pause() {
  if (isStart_) {
    timeElapsed_ += chrono::steady_clock::now() - beg_;
    isStart_ = false;
  }
}

chrono::steady_clock::duration Stopwatch::getTime() const {
  if (isStart_) {
    return timeElapsed_ + offset_ + (chrono::steady_clock::now() - beg_);
  } else {
    return timeElapsed_ + offset_;
  }
}

void Stopwatch::resetClock() {
  timeElapsed_ = chrono::steady_clock::duration::zero();
  offset_ = chrono::steady_clock::duration::zero();
}

} // namespace np_torch
