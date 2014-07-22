function getData(url, callback) {
	var request = new XMLHttpRequest();
	request.open("GET", url);
	request.onreadystatechange = function() {
		if (request.readyState === 4 && request.status === 200) {
			callback(request.responseText);
		}
	};
	request.send();
}

function preload(data) {
	var preload_div = document.getElementById("preload-div");
	preload_div.innerHTML = "";
	for (var i = 0; i < data.length; i ++) {
		for (var j = 0; j < data[i].pics.length; j ++) {
			var img = document.createElement("img");
			img.setAttribute("src", data[i].pics[j].url);
			preload_div.appendChild(img);
		}
	}
}

var cur_top = 0;
getData("/api?start=0&num=20", function(data) {
	//document.write(data);
	data = JSON.parse(data);
	var index_i = 0, index_j = 0;
	var cols = new Array();
	cols[0] = document.getElementById("col1");
	cols[1] = document.getElementById("col2");
	cols[2] = document.getElementById("col3");
	cols[3] = document.getElementById("col4");
	for (var i = 0; i < 5; i ++) {
		for (var j = 0; j < 4; j ++) {
			var mod_img = document.createElement("div");
			mod_img.setAttribute("class", "mod-img");
			var pic_area = document.createElement("div");
			pic_area.setAttribute("class", "img-content");
			pic_area.setAttribute("data-bind", "style:style;conCls:cls");
			pic_area.setAttribute("style", "height: auto;");
			var link = document.createElement("a");
			link.setAttribute("href", "javascript:void(0)");
			link.setAttribute("id", i + " " + j);
			link.addEventListener("click", function() {
				var ids = this.id.split(" ");
				index_i = parseInt(ids[0]);
				index_j = parseInt(ids[1]);
				var index = 0;
				
				var full_div = document.createElement("div");
				full_div.setAttribute("class", "app-preview");
				full_div.setAttribute("id", "full-screen-display");
				var show_div = document.createElement("div");
				show_div.setAttribute("class", "app-preview-mask");
				var box_div = document.createElement("div");
				box_div.setAttribute("class", "app-preview-picBox");
				var cur_pic = document.createElement("img");
				cur_pic.setAttribute("src", data[index_i * 4 + index_j].pics[index].url);
				index ++;
				cur_pic.setAttribute("class", "app-preview-picBox-pic");
				box_div.appendChild(cur_pic);
				full_div.appendChild(show_div);
				full_div.appendChild(box_div);
				document.getElementsByTagName("body")[0].appendChild(full_div);
				cur_top = $("body").scrollTop();
				$("body").scrollTop(0);
				$('#full-screen-display').mousewheel(function(event) {
					return false;
				});

				var k_ev = new Kibo();
				k_ev.down('esc', function() {
					var full_div = document.getElementById("full-screen-display");
					//TODO undefined?
					full_div.parentNode.removeChild(full_div);
					$("body").scrollTop(cur_top);
					return false;
				});

				k_ev.down('right', function() {
					var len = data[index_i * 4 + index_j].pics.length;
					if (index < len) {
						cur_pic.setAttribute("src", data[index_i * 4 + index_j].pics[index].url);
						index ++;
					} else if (index_j < 3) {
						index_j ++;
						index = 0;
						cur_pic.setAttribute("src", data[index_i * 4 + index_j].pics[index].url);
					} else if (index_i < 4) {
						index_i ++;
						index_j = 0;
						index = 0;
						cur_pic.setAttribute("src", data[index_i * 4 + index_j].pics[index].url);
					} else {
						//TODO
					}
					return false;
				});
				k_ev.down('left', function() {
					if (index > 0) {
						index --;
						cur_pic.setAttribute("src", data[index_i * 4 + index_j].pics[index].url);
					} else if (index_j > 0) {
						index_j --;
						index = data[index_i * 4 + index_j].pics.length - 1;
						cur_pic.setAttribute("src", data[index_i * 4 + index_j].pics[index].url);
					} else if (index_i > 0) {
						index_i --;
						index_j = 3;
						index = data[index_i * 4 + index_j].pics.length - 1;
						cur_pic.setAttribute("src", data[index_i * 4 + index_j].pics[index].url);
					} else {
						//TODO
					}
					return false;
				});
			}, false);
			var img = document.createElement("img");
			img.setAttribute("class", "img-responsive");
			img.setAttribute("src", data[i * 4 + j].pics[0].url);
			img.setAttribute("alt", data[i * 4 + j].title);
			link.appendChild(img);
			pic_area.appendChild(link);
			var tag_area = document.createElement("div");
			tag_area.setAttribute("class", "ext-info");
			mod_img.appendChild(pic_area);
			mod_img.appendChild(tag_area);
			cols[j].appendChild(mod_img);
		}
	}

	preload(data);
});