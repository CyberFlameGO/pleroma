(window.webpackJsonp=window.webpackJsonp||[]).push([[23],{852:function(n,o,a){"use strict";a.r(o),a.d(o,"default",(function(){return S}));var e,t,i,c=a(0),r=a(2),s=(a(9),a(6),a(8)),d=a(1),l=a(65),u=a.n(l),m=(a(3),a(15)),b=a(7),f=a(21),p=a(5),j=a.n(p),O=a(16),h=a.n(O),k=a(306),g=a(757),v=a(763),M=a(84),y=a(53);var _,D,w,U=Object(b.f)({unblockDomain:{id:"account.unblock_domain",defaultMessage:"Unblock domain {domain}"}}),C=Object(b.g)((i=t=function(n){Object(s.a)(a,n);var o;o=a;function a(){for(var o,a=arguments.length,e=new Array(a),t=0;t<a;t++)e[t]=arguments[t];return o=n.call.apply(n,[this].concat(e))||this,Object(d.a)(Object(r.a)(o),"handleDomainUnblock",(function(){o.props.onUnblockDomain(o.props.domain)})),o}return a.prototype.render=function(){var n=this.props,o=n.domain,a=n.intl;return(Object(c.a)("div",{className:"domain"},void 0,Object(c.a)("div",{className:"domain__wrapper"},void 0,Object(c.a)("span",{className:"domain__domain-name"},void 0,Object(c.a)("strong",{},void 0,o)),Object(c.a)("div",{className:"domain__buttons"},void 0,Object(c.a)(y.a,{active:!0,icon:"unlock",title:a.formatMessage(U.unblockDomain,{domain:o}),onClick:this.handleDomainUnblock})))))},a}(f.a),Object(d.a)(t,"propTypes",{domain:j.a.string,onUnblockDomain:j.a.func.isRequired,intl:j.a.object.isRequired}),e=i))||e,R=a(48),q=Object(b.f)({blockDomainConfirm:{id:"confirmations.domain_block.confirm",defaultMessage:"Block entire domain"}}),N=Object(b.g)(Object(m.connect)((function(){return function(){return{}}}),(function(n,o){var a=o.intl;return{onBlockDomain:function(o){n(Object(R.d)("CONFIRM",{message:Object(c.a)(b.b,{id:"confirmations.domain_block.message",defaultMessage:"Are you really, really sure you want to block the entire {domain}? In most cases a few targeted blocks or mutes are sufficient and preferable.",values:{domain:Object(c.a)("strong",{},void 0,o)}}),confirm:a.formatMessage(q.blockDomainConfirm),onConfirm:function(){return n(Object(M.e)(o))}}))},onUnblockDomain:function(o){n(Object(M.h)(o))}}}))(C)),T=a(1049);var I=Object(b.f)({heading:{id:"column.domain_blocks",defaultMessage:"Blocked domains"},unblockDomain:{id:"account.unblock_domain",defaultMessage:"Unblock domain {domain}"}}),S=Object(m.connect)((function(n){return{domains:n.getIn(["domain_lists","blocks","items"]),hasMore:!!n.getIn(["domain_lists","blocks","next"])}}))(_=Object(b.g)((w=D=function(n){Object(s.a)(a,n);var o;o=a;function a(){for(var o,a=arguments.length,e=new Array(a),t=0;t<a;t++)e[t]=arguments[t];return o=n.call.apply(n,[this].concat(e))||this,Object(d.a)(Object(r.a)(o),"handleLoadMore",u()((function(){o.props.dispatch(Object(M.f)())}),300,{leading:!0})),o}var e=a.prototype;return e.componentWillMount=function(){this.props.dispatch(Object(M.g)())},e.render=function(){var n=this.props,o=n.intl,a=n.domains,e=n.shouldUpdateScroll,t=n.hasMore,i=n.multiColumn;if(!a)return Object(c.a)(g.a,{},void 0,Object(c.a)(k.a,{}));var r=Object(c.a)(b.b,{id:"empty_column.domain_blocks",defaultMessage:"There are no blocked domains yet."});return(Object(c.a)(g.a,{bindToDocument:!i,icon:"minus-circle",heading:o.formatMessage(I.heading)},void 0,Object(c.a)(v.a,{}),Object(c.a)(T.a,{scrollKey:"domain_blocks",onLoadMore:this.handleLoadMore,hasMore:t,shouldUpdateScroll:e,emptyMessage:r,bindToDocument:!i},void 0,a.map((function(n){return Object(c.a)(N,{domain:n},n)})))))},a}(f.a),Object(d.a)(D,"propTypes",{params:j.a.object.isRequired,dispatch:j.a.func.isRequired,shouldUpdateScroll:j.a.func,hasMore:j.a.bool,domains:h.a.orderedSet,intl:j.a.object.isRequired,multiColumn:j.a.bool}),_=w))||_)||_}}]);
//# sourceMappingURL=domain_blocks.js.map