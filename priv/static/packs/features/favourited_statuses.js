(window.webpackJsonp=window.webpackJsonp||[]).push([[24],{799:function(t,e,a){"use strict";a.r(e),a.d(e,"default",(function(){return C}));var o,n,s,i=a(0),c=a(2),u=a(7),l=a(1),r=a(62),d=a.n(r),h=a(3),p=a.n(h),b=a(13),f=a(5),j=a.n(f),O=a(14),m=a.n(O),g=a(204),v=a(731),M=a(733),I=a(250),w=a(1038),y=a(6),L=a(18),k=Object(y.f)({heading:{id:"column.favourites",defaultMessage:"Favourites"}}),C=Object(b.connect)((function(t){return{statusIds:t.getIn(["status_lists","favourites","items"]),isLoading:t.getIn(["status_lists","favourites","isLoading"],!0),hasMore:!!t.getIn(["status_lists","favourites","next"])}}))(o=Object(y.g)((s=n=function(t){function e(){for(var e,a=arguments.length,o=new Array(a),n=0;n<a;n++)o[n]=arguments[n];return e=t.call.apply(t,[this].concat(o))||this,Object(l.a)(Object(c.a)(e),"handlePin",(function(){var t=e.props,a=t.columnId,o=t.dispatch;o(a?Object(I.h)(a):Object(I.e)("FAVOURITES",{}))})),Object(l.a)(Object(c.a)(e),"handleMove",(function(t){var a=e.props,o=a.columnId;(0,a.dispatch)(Object(I.g)(o,t))})),Object(l.a)(Object(c.a)(e),"handleHeaderClick",(function(){e.column.scrollTop()})),Object(l.a)(Object(c.a)(e),"setRef",(function(t){e.column=t})),Object(l.a)(Object(c.a)(e),"handleLoadMore",d()((function(){e.props.dispatch(Object(g.g)())}),300,{leading:!0})),e}Object(u.a)(e,t);var a=e.prototype;return a.componentWillMount=function(){this.props.dispatch(Object(g.h)())},a.render=function(){var t=this.props,e=t.intl,a=t.shouldUpdateScroll,o=t.statusIds,n=t.columnId,s=t.multiColumn,c=t.hasMore,u=t.isLoading,l=!!n,r=Object(i.a)(y.b,{id:"empty_column.favourited_statuses",defaultMessage:"You don't have any favourite toots yet. When you favourite one, it will show up here."});return p.a.createElement(v.a,{bindToDocument:!s,ref:this.setRef,label:e.formatMessage(k.heading)},Object(i.a)(M.a,{icon:"star",title:e.formatMessage(k.heading),onPin:this.handlePin,onMove:this.handleMove,onClick:this.handleHeaderClick,pinned:l,multiColumn:s,showBackButton:!0}),Object(i.a)(w.a,{trackScroll:!l,statusIds:o,scrollKey:"favourited_statuses-"+n,hasMore:c,isLoading:u,onLoadMore:this.handleLoadMore,shouldUpdateScroll:a,emptyMessage:r,bindToDocument:!s}))},e}(L.a),Object(l.a)(n,"propTypes",{dispatch:j.a.func.isRequired,shouldUpdateScroll:j.a.func,statusIds:m.a.list.isRequired,intl:j.a.object.isRequired,columnId:j.a.string,multiColumn:j.a.bool,hasMore:j.a.bool,isLoading:j.a.bool}),o=s))||o)||o}}]);
//# sourceMappingURL=favourited_statuses.js.map