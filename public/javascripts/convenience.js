Convenience = {
	selectSelected: function() { $('.selected').select(); },
	filesizeformat: function() {
		$('.filesize').each(function() {
			this.innerHTML = $.filesizeformat(this.innerHTML);
		});
	},
	timeago: function() {
		$('.timeago').each(function() {
			this.innerHTML = $.timeago(this.innerHTML);
		});
	},

	applyGeneric: function() {
		this.selectSelected();
		this.filesizeformat();
		this.timeago();
	}
};
