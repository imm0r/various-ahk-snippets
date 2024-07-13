define(["jquery", "underscore", "backbone", "text!templates/view/" + DEVICE_DIR + "/articleList_" + objCommData.forum.forumType + ".html", "view/bbsError", "forumComm", "forumUi", "forumUtil", "polyglot"], function (t, e, i, a, r, l, n, o) {
    var c = {},
    s = i.View.extend({
        articleData: {},
        useBack: !1,
        initialize: function (t) {
            void 0 != t && (c = t)
        },
        render: function (t) {
            void 0 != t && "" != t ? (this.useBack = !0, this.articleData = t, this.articleData.list = JSON.parse(JSON.stringify(t.allList))) : this.useBack = !1,
            this.$el.empty(),
            this.addArticleList()
        },
        addArticleList: function () {
            this.$el.attr("class", (l.commData.isPC ? "article_list_" : "article_list ") + this.articleData.viewType);
            var i = t("<div>" + a + "</div>").find("#articleAppendList").html(),
            r = this.model.get("forum"),
            n = o.getStorage("articleReadIn" + r.id);
            n = null == n ? {}
             : JSON.parse(n);
            var c = {
                imgPath: IMAGE_PATH,
                list: this.articleData.list,
                readArticles: n,
                viewType: this.articleData.viewType,
                getDate: o.getDate,
                getDateDetail: o.getDateDetail,
                getNumber: o.getNumber,
                makeReactionInfo: this.makeReactionInfo,
                setWriterLevel: this.setWriterLevel,
                defaultProfileImg: l.commData.profileDefaultImgUrl,
                category: l.commData.category,
                isOfficial: l.commData.isOfficial,
                getThumbnail: this.getThumbnail,
                getPlainText: this.getPlainText,
                getPureTextLength: this.getPureTextLength,
                menuList: l.parseMenuList({
                    useLink: !1,
                    useGroup: !1
                }),
                defaultBbsOrder: this.model.get("forum").defaultBbsOrder,
                isOldSticker: o.isOldSticker,
                setImgHeight: this.setImgHeight
            };
            void 0 != this.articleData.page && "search" == this.articleData.page && (c.page = this.articleData.page),
            void 0 != this.articleData.customData && (c.customData = this.articleData.customData),
            c.isComment = void 0 == this.articleData.isComment ? !1 : this.articleData.isComment,
            c.isMyComment = void 0 == this.articleData.isMyComment ? !1 : this.articleData.isMyComment,
            c.useMenuSeq = void 0 == this.articleData.useMenuSeq ? !1 : this.articleData.useMenuSeq,
            c.showAtcRecent = !1,
            1 == c.defaultBbsOrder && (void 0 != this.articleData.page && "search" == this.articleData.page && void 0 == this.articleData.customData ? c.showAtcRecent = !1 : c.showAtcRecent = !0);
            var s = e.template(i, {
                variable: "d"
            })(c);
            t(".cmn_alert").hide(),
            this.$el.append(s),
            this.useBack && t(".lazyImg").lazyload({
                threshold: 100
            })
        },
        onClose: function () {
            null != this.bbsErrorView && this.bbsErrorView.remove()
        },
        events: {
            "click .atc_thumbnail": "setVideo",
            "click a[data-link]": "moveLink",
            "click div[data-link]": "moveLink",
            "click div[data-router]": "moveRouter",
            "click p[data-router]": "moveRouter",
            "click li[data-router]": "moveRouter",
            "click .btn_cmt_del": "clickCommentDelBtn"
        },
        getThumbnail: function (t) {
            return t.indexOf("sgimage") > -1 ? t = t.replace("_THUMB", "") : t.indexOf("ytimg") > -1 && t.indexOf("mqdefault.jpg") < 0 && (t = t.replace("default.jpg", "mqdefault.jpg")),
            t
        },
        setImgHeight: function (e) {
            if (void 0 != e.attachFileInfo) {
                var i,
                a = document.documentElement.clientWidth;
                t("body").hasClass("landscape") && (a = document.documentElement.clientHeight);
                for (var r = 0; r < e.attachFileInfo.length; r++)
                    if (e.attachFileInfo[r].thumbnailUrl == e.thumbnailUrl) {
                        if (void 0 == e.attachFileInfo[r].thumbnails) {
                            i = e.attachFileInfo[r].thumbnailHeight * a / e.attachFileInfo[r].thumbnailWidth;
                            break
                        }
                        for (var l = 0; l < e.attachFileInfo[r].thumbnails.length; l++)
                            if ("lp" == e.attachFileInfo[r].thumbnails[l].tType) {
                                i = e.attachFileInfo[r].thumbnails[l].tHeight * a / e.attachFileInfo[r].thumbnails[l].tWidth;
                                break
                            }
                        if (void 0 != i)
                            break
                    }
                return void 0 != i ? Math.ceil(i) : void 0
            }
        },
        moveLink: function (e) {
            var a = t(e.currentTarget).data("link");
            -1 == a.indexOf("profile/-100") && void 0 != a && window.open(i.history.root + a, "_blank")
        },
        setData: function (t) {
            this.articleData = t
        },
        makeReactionInfo: function (t) {
            for (var i = "", a = e.sortBy(t, "cnt").reverse(), r = 0; 2 > r; r++)
                a[r].cnt > 0 && (i += "<em class='ic s_emo" + a[r].type + "'></em>");
            return i
        },
        setWriterLevel: function (t) {
            if (void 0 != t) {
                var e = {};
                e = l.getLevelObj(t);
                var i = "";
                return i = l.commData.isOfficial ? e.levelImgUrl : e.levelName
            }
        },
        setVideo: function (e) {
            if (t(e.currentTarget).find(".a_video").length > 0) {
                var i = t(e.currentTarget).find(".a_video").attr("id");
                n.youtube.set(i, i, {
                    addvars: {
                        autoplay: 1
                    }
                }),
                t(e.currentTarget).find("span").hide()
            }
        },
        moveRouter: function (e) {
            void 0 != t(e.currentTarget).data("router") && l.router(t(e.currentTarget).data("router"), !0)
        },
        clickCommentDelBtn: function (t) {
            t.stopPropagation(),
            c.parentViewFunction(t)
        },
        getPlainText: function (e) {
            return t("#appView").hasClass("pg_profile") ? e.replace(/(<([^>]+)>)/gi, "") : e
        },
        getPureTextLength: function (t) {
            return t.replace(/\s/gi, "").length
        }
    });
    return s
});
