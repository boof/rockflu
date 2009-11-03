jQuery.fn.playlist = function() {
	var list = this;
	if(list.length == 0) return;

	var defaultMode = function(playlist) {
		this.playlist = playlist;

		this.songFinished = function() {
			if (this.playlist.length == this.playlist.songIndex + 1) return;
			this.playlist.songIndex++;
			this.playlist.play();
		}
		this.playNext = function() {
			if (this.playlist.songIndex == this.playlist.length - 1)
				this.playlist.songIndex = 0;
			else
				this.playlist.songIndex++;

			this.playlist.play();
		}
		this.playPrevious = function() {
			if (this.playlist.songIndex == 0)
				this.playlist.songIndex = this.playlist.length - 1;
			else
				this.playlist.songIndex--;

			this.playlist.play();
		}

		return this;
	}

	list.songIndex = 0;
	list.mode = defaultMode(list);
	list.player = $('#jPlayer');

	list.display = {
		show: function() { $('#playerContainer').show(); },
		setTitle: function(title) { $('#songTitle').html(title); },
		update: function(loaded, p, P, t, T) {
			var tLocal = new Date(t),
				TLocal = new Date(T),
				tMinutes = tLocal.getUTCMinutes(),
				tSeconds = tLocal.getUTCSeconds(),
				TMinutes = TLocal.getUTCMinutes(),
				TSeconds = TLocal.getUTCSeconds(),
				ptMin = (tMinutes < 10) ? '0' + tMinutes : tMinutes,
				ptSec = (tSeconds < 10) ? '0' + tSeconds : tSeconds,
				ttMin = (TMinutes < 10) ? '0' + TMinutes : TMinutes,
				ttSec = (TSeconds < 10) ? '0' + TSeconds : TSeconds;

			$('#playTime').text(ptMin + ':' + ptSec);
			$('#totalTime').text(ttMin + ':' + ttSec);
		}
	}
	list.updateComponents = function() {
		var song = this.get(this.songIndex);
		this.display.setTitle(song.title);
		this.player.setFile(song.href);
	}
	list.play = function() {
		this.updateComponents();
		this.player.play();
	}
	list.setSong = function(song) {
		this.songIndex = this.index(song);
		this.play();
	}
	list.songFinished = function() {
		this.mode.songFinished();
	}
	list.playNext = function() {
		this.mode.playNext();
	}
	list.playPrevious = function() {
		this.mode.playPrevious();
	}

	list.click(function(e) {
		e.preventDefault();
		list.setSong(this);
	})
	.player.jPlayer({
		swfPath: '/flash',
		ready: function() { list.updateComponents(); }
	})
	// TODO: move jPlayerId stuff into own object
	.jPlayerId("play", "playerPlay")
	.jPlayerId("pause", "playerPause")
	.jPlayerId("loadBar", "playerProgressLoadBar")
	.jPlayerId("playBar", "playerProgressPlayBar")
	.jPlayerId("volumeMin", "playerVolumeMin")
	.jPlayerId("volumeMax", "playerVolumeMax")
	.jPlayerId("volumeBar", "playerVolumeBar")
	.jPlayerId("volumeBarValue", "playerVolumeBarValue")
	.onProgressChange(function(loaded, p, P, t, T) {
		list.display.update(loaded, p, P, t, T);
	})
	.onSoundComplete(function() {
		list.songFinished();
	});

	list.display.show();
};
