(window.webpackJsonp=window.webpackJsonp||[]).push([[4,5],{267:function(t,n,e){},276:function(t,n,e){"use strict";e(267)},297:function(t,n,e){"use strict";e.r(n);var a={render:t=>t("div",{class:"carbon-ads",attrs:{id:"native-carbon"}}),mounted(){this.load()},watch:{$route(t,n){t.path!==n.path&&this.$el.querySelector("#carbonads")&&(this.$el.innerHTML="",this.load())}},methods:{initCarbon(){const{_bsa:t}=window;void 0!==t&&t&&t.init("default","CK7I62QJ","placement:grapesjscomdocs",{target:"#native-carbon"})},load(){const t=document.createElement("script");t.src="//cdn.carbonads.com/carbon.js?serve=CEAIVK77&placement=grapesjscom",t.setAttribute("id","_carbonads_js");const n=document.getElementById("native-carbon");n&&n.appendChild(t)}}},o=(e(276),e(14)),s=Object(o.a)(a,void 0,void 0,!1,null,null,null);n.default=s.exports},385:function(t,n,e){"use strict";e.r(n);var a=e(318),o=e(297),s={components:{Layout:a.a,CarbonAds:o.default}},r=e(14),c=Object(r.a)(s,(function(){var t=this._self._c;return t("Layout",[t("CarbonAds",{attrs:{slot:"sidebar-top"},slot:"sidebar-top"})],1)}),[],!1,null,null,null);n.default=c.exports}}]);