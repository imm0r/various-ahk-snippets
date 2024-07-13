"use strict";
define(["jquery", "underscore", "backbone", "text!templates/router/" + DEVICE_DIR + "/profile.html", "forumComm", "forumUi", "forumUtil", "polyglot"], function (t, e, a, i, o, r, s) {
    var l,
    n = o.commData.isPC,
    c = o.commData.isIngame,
    m = s.checkLogin({
        useAlert: !1
    }),
    f = a.View.extend({
        el: "#appView",
        vData: {},
        mem: {},
        initialize: function (t) {
            var e = this;
            o.profile.setResources(e, s),
            o.initPage({
                viewType: this.el.id,
                pageName: "profile",
                isRouter: t.isRouter,
                isScrollTop: !1
            }),
            this.vData.seq = t.param[0],
            this.vData.pageNo = t.param[1],
            null == t.query ? (this.vData.type = "article", this.vData.filter = "ARTICLE") : (this.vData.useTarget = t.query.useTarget, t.query.type.indexOf("article_") > -1 ? (this.vData.type = "article", this.vData.filter = t.query.type.split("_")[1].toUpperCase()) : this.vData.type = t.query.type),
            this.vData.useSubscribe = !0,
            this.vData.forum = this.model.get("forum"),
            this.vData.user = this.model.get("user"),
            l = "PASSWORD_LAYER_INFO_" + this.vData.forum.id,
            !n && m && this.vData.user.member.memberSeq == this.vData.seq && o.commData.signChannel.useCharacter && (o.commData.isOfficial && this.vData.user.level < 98 || !o.commData.isOfficial) && s.callAjax({
                url: "/api/game/" + e.vData.forum.gameCode + "/" + e.vData.forum.forumType + "/forum/" + e.vData.forum.id + "/member/" + e.vData.user.member.memberSeq + "/password"
            }, function (t) {
                e.vData.password = t
            })
        },
        render: function () {
            if (void 0 != this.vData.seq) {
                var t = this,
                e = this.vData.forum,
                a = this.vData.user;
                m && a.member.memberSeq == this.vData.seq ? (this.vData.isMy = !0, s.callAjax({
                        url: "/api/game/" + e.gameCode + "/" + e.forumType + "/forum/" + e.id + "/member/" + this.vData.seq + "/alarm/count?type=0",
                        frogArg: {
                            eLogCd: ["alarm", "count", this.vData.seq, 0]
                        }
                    }, function (e) {
                        t.alarmCount = e.count
                    })) : (this.vData.isMy = !1, "alarm" == this.vData.type && (this.vData.type = "article")),
                s.callAjax({
                    url: "/api/game/" + e.gameCode + "/" + e.forumType + "/forum/" + e.id + "/member/" + this.vData.seq,
                    frogArg: {
                        eLogCd: ["member", "view", this.vData.seq, 0]
                    }
                }, function (e) {
                    var a = 0,
                    i = function () {
                        t.vData.isMy && void 0 == t.alarmCount && 30 > a ? setTimeout(function () {
                            a++,
                            i()
                        }, 100) : t.afterAjax(e.member)
                    };
                    i()
                }, function (t) {
                    4e3 == t.code || 2040 == t.code || 12001 == t.code ? o.router("/") : r.alert(t.msg)
                })
            } else
                s.badUrl()
        },
        afterAjax: function (a) {
            this.mem.nickname = a.nickname,
            o.browserTitle({
                val: polyglot.t("META.TITLE.1", {
                    nickname: a.nickname
                })
            }),
            void 0 == a.code && (a.code = 0),
            void 0 == a.character && (a.character = {
                    charInfo: []
                });
            var l = [],
            m = ' target="_blank"';
            c && (m = ""),
            e.each(a.hashtagList, function (t) {
                l.push(t.replace(t, '<li class="skin_bg_elv_cont"><a data-log-cd="Forum_Profile, Field_Click, Profile_hashtag" class="skin_pri_font">' + t + "</a></li>"))
            });
            var f = e.template(i, {
                variable: "d"
            })({
                imgPath: IMAGE_PATH,
                mem: a,
                profileDefaultImgUrl: o.commData.profileDefaultImgUrl,
                txthashtagList: l.join(""),
                isMy: this.vData.isMy,
                getNumber: s.getNumber,
                isOfficial: o.commData.isOfficial,
                alarmCount: this.alarmCount,
                coppaInfo: o.commData.coppaInfo,
                useSubscribe: this.vData.useSubscribe
            });
            if (this.$el.html(f), o.profile.append("wrapGpProfile", a, o.getLevelObj(a.memberLevelCd), this.vData.isMy, o.commData.isOfficial, s.getNumber, o.getServerName), n) {
                if (void 0 != a.isBlockedUser && a.isBlockedUser)
                    return void t("#profileTabs").css("display", "none");
                var u = this.vData.type;
                "article" == this.vData.type && void 0 != this.vData.filter && (u += "_" + this.vData.filter.toLowerCase()),
                this.renderTab(u)
            } else {
                if (r.setIngameLnb({
                        title: a.nickname
                    }), this.setMobilePasswordNoti(), void 0 != a.isBlockedUser && a.isBlockedUser)
                    return void t("#elSummaryBarLine").css("display", "none");
                this.setMobileTab()
            }
        },
        setMobileTab: function (e) {
            void 0 != this.vData.useTarget && "yes" == this.vData.useTarget && setTimeout(function () {
                t(window).scrollTop(t("#elSummaryBarLine").offset().top - 48)
            }, 500),
            t("#gnb_title_atc").hide(),
            t("#gnb_title_atc").off("click"),
            t("#gnb_title_atc").attr("data-router", null);
            var a = t(window).scrollTop(),
            i = t(window).scrollTop(),
            o = "down",
            s = "down";
            t(window).on("scroll.profile", function () {
                i = t(window).scrollTop();
                var e = 3,
                r = i - a;
                r > e ? o = "down" : -e > r && (o = "up"),
                s = o,
                a = i,
                0 == i || i < t(".cmn_tab")[0].offsetTop + t(".cmn_tab")[0].clientHeight ? (t("#gnb_title_atc").hide(), t("#gnb_title_atc").off("click.gnbTitle")) : (t("#gnb_title_atc").show(), t("#gnb_title_atc").on("click.gnbTitle", function (e) {
                        t(window).scrollTop(0)
                    }))
            }),
            t("#sdkCtrlAppview a").off("click"),
            t("#sdkCtrlAppview .sdk_bt_list").hide(),
            "article" == this.vData.type && void 0 == this.vData.filter && (this.vData.filter = "ARTICLE"),
            "alarm" != this.vData.type || this.vData.isMy || (this.vData.type = "article", this.vData.filter = "ARTICLE"),
            this.fnTab({
                currentTarget: t("#tab_" + this.vData.type + (void 0 == this.vData.filter ? "" : "_" + this.vData.filter.toLowerCase()) + " a")[0]
            }),
            t("#tab_" + this.vData.type + (void 0 == this.vData.filter ? "" : "_" + this.vData.filter.toLowerCase())).addClass("on"),
            t(window).scrollTop() <= 0 && t("#topSdkBtn").hide(),
            t("#topSdkBtn a").on("click", function (e) {
                t(window).scrollTop(0)
            }),
            r.setShowSwipe()
        },
        setMobilePasswordNoti: function () {
            if (m && o.commData.signChannel.useCharacter && this.vData.user.member.memberSeq == this.vData.seq && void 0 != this.vData.password && !this.vData.password.isSet) {
                var t = JSON.parse(s.getStorage(l));
                if (null != t) {
                    if (t.STOP_FLAG)
                        return;
                    if (void 0 != t.TIME && Date.now() - t.TIME < 864e5)
                        return
                }
                r.layer.open("passwordNotiLayer")
            }
        },
        onClose: function () {
            void 0 != this.subView && this.subView.remove(),
            n || (t("#sdkCtrlAppview .sdk_bt_list").hide(), t("#topSdkBtn").hide(), r.unSetShowSwipe(), t("#topSdkBtn a").off("click"), t("#gnb_title_atc").off("click.gnbTitle"), t("#appView").empty()),
            t(window).off("scroll.profile")
        },
        events: {
            "click #wrapProfileTab a": "fnRouter",
            "click #infoBtSubscribe": "fnSubscribe",
            "mouseover #infoBtSubscribe.on": "overSubscribe",
            "mouseout #infoBtSubscribe.on": "outSubscribe",
            "click #infoBtUnblock": "fnUnblock",
            "click #lstRelate li a": "hashTagClick",
            "click #profileExtend": "infoTextExtendToggle",
            "click #passwordNotiLayer .n_pop_close": "passwordCloseClick",
            "click #passwordNotiStop": "passwordNotiStopClick",
            "click #passwordSet": "passwordSetClick"
        },
        infoTextExtendToggle: function (e) {
            t(".info_text.profile_bt").toggle(),
            t(".info_text.profile_desc").toggle(),
            t(".t3 .extend_bt").toggleClass("on")
        },
        fnRouter: function (t) {
            o.router("/profile/" + this.vData.seq + "?type=" + t.currentTarget.parentNode.id.replace("tab_", "") + "&useTarget=yes", !1),
            this.fnTab(t)
        },
        searchUrl: function (t) {
            return new URLSearchParams(t)
        },
        fnTab: function (e) {
            var a = e.currentTarget.parentNode.id.replace("tab_", "");
            this.subView && (this.subView.remove(), delete this.subView),
            "article_comment" == a ? (this.vData.type = "article", this.vData.filter = "COMMENT") : "article_article" == a ? (this.vData.type = "article", this.vData.filter = "ARTICLE") : this.vData.type = a,
            t("#wrapProfileTab li").removeClass("on"),
            t("#tab_" + a).addClass("on"),
            "alarm" == a ? t("#tab_alarm_noti").css("display", "block") : t("#tab_alarm_noti").css("display", "none"),
            this.renderTab(a)
        },
        renderTab: function (e) {
            var a = this,
            i = function (i) {
                var o = {
                    model: a.model,
                    seq: a.vData.seq,
                    type: a.vData.type,
                    mem: a.mem,
                    filter: a.vData.filter
                };
                "article" == a.vData.type && (null != a.vData.pageNo ? o.pageNo = a.vData.pageNo : o.pageNo = 1),
                a.subView = new i(o),
                a.subView.setElement("#wrapProfileCont").render(),
                n ? (t("#tab_" + e).addClass("on"), "alarm" == e ? t("#tab_alarm_noti").css("display", "block") : t("#tab_alarm_noti").css("display", "none")) : t(".cmn_tab_lst").scrollLeft(t(".cmn_tab_lst li.on").innerWidth() / 2 + t(".cmn_tab_lst li.on")[0].offsetLeft - t(window).width() / 2),
                a.searchUrl(window.location.href) && a.searchUrl(window.location.href).get("useTarget") && "yes" == a.searchUrl(window.location.href).get("useTarget") && setTimeout(function () {
                    t(window).scrollTop(t("#elSummaryBarLine").offset().top - 48)
                }, 500)
            },
            o = a.vData.type;
            ("follow" == a.vData.type || "follower" == a.vData.type) && (o = "member"),
            require(["view/profile/" + o + "List", "text!templates/view/profile_" + o + "List.html"], function (t) {
                i(t)
            })
        },
        fnSubscribe: function (e) {
            if (("delete" == t(e.currentTarget).data("method") || s.checkLogin({
                        useRedirect: !0,
                        useRestrict: !0
                    })) && s.checkLogin()) {
                var a = this,
                i = this.vData.forum,
                r = (this.vData.user, t(e.currentTarget)),
                l = r.data("method"),
                c = r.data("seq"),
                m = parseInt(r.data("originCnt")),
                f = {
                    eLogCd: ["subcription", "post" == l ? "follow" : "unfollow", "", c]
                };
                s.callAjax({
                    type: l,
                    url: "/api/game/" + i.gameCode + "/" + i.forumType + "/forum/" + i.id + "/member/" + c + "/follow",
                    frogArg: f
                }, function (e) {
                    "follower" == a.vData.type ? a.render() : "post" == l ? (r.addClass("on"), r.data("method", "delete"), r.data("originCnt", m + 1), n ? (r.html(polyglot.t("ROUTER.PROFILE.3") + " " + s.getNumber(m + 1)), r.css({
                                "background-color": "#fff",
                                border: "1px solid #3582d8",
                                color: "#3582d8"
                            })) : r.html("<span>" + polyglot.t("ROUTER.PROFILE.3") + " " + s.getNumber(m + 1) + "</span>"), n && t("#tab_follower em:eq(0)").text(s.getNumber(m + 1)), o.log(["Forum_Profile", "Button_Click", "Profile_follow"]), o.commData.isIngame && o.logSdk(600, 3, {
                            targetMemberSeq: c
                        })) : (r.removeClass("on"), r.data("method", "post"), r.data("originCnt", m - 1), n ? (r.html("+ " + polyglot.t("ROUTER.BBS.CONTENTS.9") + " " + s.getNumber(m - 1)), r.css({
                                "background-color": "#3582d8",
                                color: "#fff"
                            })) : r.html("<span>+ " + polyglot.t("ROUTER.BBS.CONTENTS.9") + " " + s.getNumber(m - 1) + "</span>"), n && t("#tab_follower em:eq(0)").text(s.getNumber(m - 1)), o.commData.isIngame && o.logSdk(600, 4, {
                            targetMemberSeq: c
                        }))
                })
            }
        },
        overSubscribe: function (e) {
            n && (t(e.currentTarget).addClass("hover"), t(e.currentTarget).html("<span>X " + polyglot.t("ROUTER.BBS.CONTENTS.10") + "</span>"))
        },
        outSubscribe: function (e) {
            n && (t(e.currentTarget).removeClass("hover"), t(e.currentTarget).html("<span>" + polyglot.t("ROUTER.PROFILE.3") + " " + t(e.currentTarget).data("originCnt") + "</span>"))
        },
        fnUnblock: function (e) {
            s.unblockMember({
                callbackSuccess: this.afterUnblock.bind(this),
                targetSeq: t(e.currentTarget).data("seq")
            })
        },
        afterUnblock: function () {
            t("#infoBtUnblock").hide(),
            t("#infoBtSubscribe").show(),
            n ? (t("#profileTabs").show(), this.renderTab(this.vData.type)) : (t("#elSummaryBarLine").show(), this.setMobileTab())
        },
        hashTagClick: function (e) {
            var i = t(e.currentTarget).text();
            c ? o.searchHashTag(i) : window.open(a.history.root + "search?keyword=" + encodeURIComponent(i), "_blank")
        },
        passwordCloseClick: function (t) {
            r.layer.close("passwordNotiLayer"),
            s.setStorage(l, JSON.stringify({
                    TIME: Date.now()
                }))
        },
        passwordNotiStopClick: function (t) {
            r.layer.close("passwordNotiLayer"),
            s.setStorage(l, JSON.stringify({
                    STOP_FLAG: !0
                }))
        },
        passwordSetClick: function (t) {
            r.layer.close("passwordNotiLayer"),
            o.router("/password/set", !0)
        }
    });
    return f
});
