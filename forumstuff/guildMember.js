define(["jquery", "underscore", "backbone", "text!templates/router/guildMember.html", "forumComm", "forumUi", "forumUtil", "polyglot", "sortable"], function (e, t, a, i, r, m, o, l, n) {
    var u = {},
    f = r.commData.isPC,
    s = (r.commData.isIngame, a.View.extend({
            el: e("#appView"),
            uiData: {},
            initialize: function (e) {
                var t = this;
                return r.profile.setResources(t, o),
                r.commData.isOfficial ? void r.router("/", !0) : (u = this.model.get("forum"), void r.initPage({
                        viewType: this.el.id,
                        pageName: "guild_mem",
                        isRouter: e.isRouter
                    }))
            },
            render: function () {
                var a = this,
                r = e("<div>" + i + "</div>").find("#memberTemp").html(),
                l = t.template(r);
                a.$el.html(l),
                f || m.setIngameLnb({
                    title: polyglot.t("ROUTER.SEARCH.3")
                }),
                o.callAjax({
                    url: "/api/game/" + u.gameCode + "/" + u.forumType + "/" + u.id + "/member/list",
                    frogArg: {
                        eLogCd: ["membmer", "list", "", ""]
                    }
                }, function (e) {
                    a.afterAjax(e)
                })
            },
            afterAjax: function (a) {
                if (0 == a.code) {
                    var m = a.memberList,
                    l = t.groupBy(m, function (e) {
                        return e.memberLevelCd
                    }),
                    n = [];
                    t.each(l, function (e, t) {
                        n.push({
                            level: parseInt(t),
                            memberList: e
                        })
                    }),
                    n = n.reverse();
                    var u = {};
                    t.each(r.commData.memberlevel, function (e) {
                        u[e.levelCd] = e.levelName
                    });
                    var f = e("<div>" + i + "</div>").find("#memberDl").html(),
                    s = t.template(f, {
                        variable: "d"
                    })({
                        memberInfo: n,
                        txtCharInfo: this.getTxtCharInfo,
                        getDate: o.getDate,
                        levelName: u,
                        defaultProfileImg: r.commData.profileDefaultImgUrl,
                        appendProfile: r.profile.appendTemp
                    });
                    e("#guildMemList").html(s)
                }
            },
            getTxtCharInfo: function (e) {
                return null != e && void 0 != e ? e.charInfo.join("&nbsp;<em>|</em>&nbsp;") : void 0
            },
            onClose: function () {},
            goHashtag: function (t) {
                r.searchHashTag(e(t.currentTarget).text())
            },
            events: {
                "click #memHash a": "goHashtag"
            }
        }));
    return s
});