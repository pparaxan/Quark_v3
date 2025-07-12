const playbackState = document.getElementById("playbackState");
const progressBar = document.getElementById("progress-bar");
const input = document.getElementById("input");
const audio = new Audio();

let queue = [];
let currentIndex = 0;
let isPlaying = false;

function handleFileSelect(event) {
  const files = Array.from(event.target.files);
  queue = files.map((file) => ({
    src: URL.createObjectURL(file),
    name: file.name,
  }));
  if (queue.length > 0) {
    currentIndex = 0;
    playAudio();
  }
}

function playAudio() {
  if (!queue.length) return;
  audio.src = queue[currentIndex].src;
  audio.play();
  isPlaying = true;
  updatePlaybackIcon();
}

function togglePlaybackState() {
  if (!queue.length) return;
  if (isPlaying) {
    audio.pause();
  } else {
    audio.play();
  }
  isPlaying = !isPlaying;
  updatePlaybackIcon();
}

function playNextTrack() {
  if (!queue.length) return;
  currentIndex = (currentIndex + 1) % queue.length;
  playAudio();
}

function playPrevTrack() {
  if (!queue.length) return;
  currentIndex = (currentIndex - 1 + queue.length) % queue.length;
  playAudio();
}

function updatePlaybackIcon() {
  playbackState.className = audio.paused
    ? "bx bx-play-circle bx-md"
    : "bx bx-pause-circle bx-md";
}

// Hook up the audio events
audio.addEventListener("ended", () => {
  playNextTrack();
});

audio.addEventListener("timeupdate", () => {
  if (audio.duration) {
    progressBar.value = (audio.currentTime / audio.duration) * 100;
  }
});

// Input and buttons
input.addEventListener("change", handleFileSelect);

progressBar.addEventListener("click", (e) => {
  const rect = progressBar.getBoundingClientRect();
  const ratio = (e.clientX - rect.left) / rect.width;
  audio.currentTime = ratio * audio.duration;
});
