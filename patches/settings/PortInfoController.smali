# Added to SecSettings as classes6.dex. Opens the XDA page; shows "No Browser Installed" if no browser exists.
.class public Lcom/saantiqz/a71port/PortInfoController;
.super Lcom/android/settings/core/BasePreferenceController;
.method public constructor <init>(Landroid/content/Context;Ljava/lang/String;)V
    .registers 3
    invoke-direct {p0, p1, p2}, Lcom/android/settings/core/BasePreferenceController;-><init>(Landroid/content/Context;Ljava/lang/String;)V
    return-void
.end method
.method public getAvailabilityStatus()I
    .registers 2
    const/4 v0, 0x0
    return v0
.end method
.method public handlePreferenceTreeClick(Landroidx/preference/Preference;)Z
    .registers 6
    invoke-virtual {p1}, Landroidx/preference/Preference;->getKey()Ljava/lang/String;
    move-result-object v0
    const-string v1, "a71_port_info"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :mine
    const/4 v0, 0x0
    return v0
    :mine
    invoke-virtual {p1}, Landroidx/preference/Preference;->getContext()Landroid/content/Context;
    move-result-object v3
    :try_start
    new-instance v0, Landroid/content/Intent;
    const-string v1, "android.intent.action.VIEW"
    const-string v2, "https://xdaforums.com/m/santi1i.12752664/"
    invoke-static {v2}, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
    move-result-object v2
    invoke-direct {v0, v1, v2}, Landroid/content/Intent;-><init>(Ljava/lang/String;Landroid/net/Uri;)V
    const/high16 v1, 0x10000000
    invoke-virtual {v0, v1}, Landroid/content/Intent;->addFlags(I)Landroid/content/Intent;
    invoke-virtual {v3, v0}, Landroid/content/Context;->startActivity(Landroid/content/Intent;)V
    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :nobrowser
    goto :done
    :nobrowser
    const-string v1, "No Browser Installed"
    const/4 v2, 0x0
    invoke-static {v3, v1, v2}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;
    move-result-object v1
    invoke-virtual {v1}, Landroid/widget/Toast;->show()V
    :done
    const/4 v0, 0x1
    return v0
.end method
