define(["jquery", "underscore", "backbone", "text!templates/view/bbsError.html", "forumComm", "forumUtil", "forumUi", "polyglot"], function (t, r, e, o, a, l, R) {
    var D,
    i = e.View.extend({
        errorData: {},
        subData: {},
        initialize: function (t) {
            this.errorData = {
                code: -1,
                type: ""
            };
            var r = t.opt;
            void 0 != r && (void 0 != r.code && (this.errorData.code = r.code), void 0 != r.type && (this.errorData.type = r.type), void 0 != r.txt && (this.errorData.txt = r.txt)),
            D = this.model.get("forum")
        },
        render: function (t) {
            var R = this;
            void 0 != t && (void 0 != t.code && (this.errorData.code = t.code), void 0 != t.type && (this.errorData.type = t.type), void 0 != t.txt && (this.errorData.txt = t.txt));
            var D = l.checkLogin({
                useAlert: !1
            });
            switch (this.errorData.code) {
            case -9999:
                break;
            case 10:
                "member" == this.errorData.type ? this.errorData.txt = polyglot.t("ROUTER.BBS.LIST.10_2") : "alarm" == this.errorData.type ? this.errorData.txt = polyglot.t("VIEW.GNB.5") : this.errorData.txt = polyglot.t("VIEW.BBS.ERROR.6");
                break;
            case 20:
                R.errorData.txt = polyglot.t("VIEW.BBS.ERROR.7", {
                    keyword: R.errorData.txt.replace(/</g, "&lt;").replace(/>/g, "&gt;")
                });
                break;
            case 4010:
                var i = {
                    useAlert: !1
                };
                l.checkLogin(i) ? (R.errorData.txt = polyglot.t("VIEW.BBS.ERROR.10"), R.errorData.desc = polyglot.t("VIEW.BBS.ERROR.11"), R.errorData.btnTxt = polyglot.t("VIEW.BBS.ERROR.12"), R.errorData.router = "/") : (R.errorData.txt = polyglot.t("VIEW.BBS.ERROR.8"), R.errorData.desc = polyglot.t("VIEW.BBS.ERROR.9"), R.errorData.btnTxt = polyglot.t("COMMON.LOGIN"), R.errorData.router = "/login");
                break;
            case 4e3:
                a.router("/", !0);
                break;
            case 51001:
            case 51002:
            case 51003:
            case 80001:
                R.errorData.txt = polyglot.t("VIEW.BBS.ERROR.21"),
                R.errorData.btnTxt = polyglot.t("VIEW.BBS.ERROR.12"),
                R.errorData.router = "/";
                break;
            case 51006:
                if (D) {
                    var s = a.commData.memberlevel[a.commData.memberlevelIdx["cd" + t.viewLevel]].levelName;
                    R.errorData.txt = polyglot.t("VIEW.BBS.ERROR.22", {
                        levelname: s
                    }),
                    R.errorData.btnTxt = polyglot.t("COMMON.APPLY"),
                    R.errorData.router = "/"
                } else
                    R.errorData.txt = polyglot.t("VIEW.BBS.ERROR.14"), R.errorData.desc = polyglot.t("VIEW.BBS.ERROR.9"), R.errorData.btnTxt = polyglot.t("COMMON.LOGIN"), R.errorData.router = "/login";
                break;
            case 50009:
            case 51007:
                R.errorData.txt = polyglot.t("VIEW.BBS.ERROR.15"),
                R.errorData.btnTxt = polyglot.t("VIEW.BBS.ERROR.12"),
                R.errorData.router = "/";
                break;
            case 80002:
                R.errorData.txt = polyglot.t("VIEW.BBS.ERROR.16"),
                R.errorData.btnTxt = polyglot.t("VIEW.BBS.ERROR.12"),
                R.errorData.router = "/";
                break;
            case 80003:
                R.errorData.desc = R.errorData.txt,
                R.errorData.txt = polyglot.t("VIEW.BBS.ERROR.16"),
                R.errorData.btnTxt = polyglot.t("VIEW.BBS.ERROR.12"),
                R.errorData.router = "/";
                break;
            default:
                R.errorData.txt = polyglot.t("VIEW.BBS.ERROR.17"),
                R.errorData.desc = polyglot.t("VIEW.BBS.ERROR.18"),
                R.errorData.btnTxt = polyglot.t("VIEW.BBS.ERROR.19"),
                R.errorData.router = e.history.getFragment()
            }
            var c = r.template(o, {
                variable: "d"
            })({
                imgPath: IMAGE_PATH,
                errorData: R.errorData
            });
            this.$el.html(c),
            this.$el.find(".cmn_alert").show()
        },
        events: {
            "click #eBtnGo ": "routerGo"
        },
        routerGo: function () {
            "/login" == this.errorData.router ? l.login() : a.router(this.errorData.router, !0)
        },
        onClose: function () {}
    });
    return i
});
