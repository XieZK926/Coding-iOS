//
//  NProjectViewController.m
//  Coding_iOS
//
//  Created by Ease on 15/3/11.
//  Copyright (c) 2015年 Coding. All rights reserved.
//

#import "NProjectViewController.h"
#import "ProjectInfoCell.h"
#import "ProjectDescriptionCell.h"
#import "NProjectItemCell.h"

//#import "ProjectItemsCell.h"
//#import "ProjectActivityListCell.h"
#import "ProjectViewController.h"
#import "Coding_NetAPIManager.h"
#import "ODRefreshControl.h"
#import "WebViewController.h"

//#import "UserInfoViewController.h"
//#import "EditTaskViewController.h"
//#import "TopicDetailViewController.h"
//#import "FileListViewController.h"
//#import "FileViewController.h"
#import "UsersViewController.h"
#import "ForkTreeViewController.h"

#import "CodeViewController.h"
#import "EaseGitButtonsView.h"
#import "UserOrProjectTweetsViewController.h"
#import "FunctionTipsManager.h"
#import "MRPRListViewController.h"
#import "WikiViewController.h"
#import "EACodeBranchListViewController.h"
#import "EACodeReleaseListViewController.h"
#import "EALocalCodeListViewController.h"


@interface NProjectViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *myTableView;
@property (nonatomic, strong) ODRefreshControl *refreshControl;

@property (strong, nonatomic) EaseGitButtonsView *gitButtonsView;

@end

@implementation NProjectViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.myTableView reloadData];
    [self refreshGitButtonsView];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.title = @"项目首页";
    
    //    添加myTableView
    _myTableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.backgroundColor = kColorTableSectionBg;
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [tableView registerClass:[ProjectInfoCell class] forCellReuseIdentifier:kCellIdentifier_ProjectInfoCell];
        [tableView registerClass:[ProjectDescriptionCell class] forCellReuseIdentifier:kCellIdentifier_ProjectDescriptionCell];
        [tableView registerClass:[NProjectItemCell class] forCellReuseIdentifier:kCellIdentifier_NProjectItemCell];
        [self.view addSubview:tableView];
        [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        tableView.estimatedRowHeight = 0;
        tableView.estimatedSectionHeaderHeight = 0;
        tableView.estimatedSectionFooterHeight = 0;
        tableView;
    });
    
    __weak typeof(self) weakSelf = self;
    _gitButtonsView = [EaseGitButtonsView new];
    _gitButtonsView.gitButtonClickedBlock = ^(NSInteger index, EaseGitButtonPosition position){
        if (position == EaseGitButtonPositionLeft) {
            [weakSelf actionWithGitBtnIndex:index];
        }else{
            [weakSelf goToUsersWithGitBtnIndex:index];
        }
    };
    [self.view addSubview:_gitButtonsView];
    [_gitButtonsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(EaseGitButtonsView_Height);
    }];

    _refreshControl = [[ODRefreshControl alloc] initInScrollView:self.myTableView];
    [_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];

    [self refresh];
}


- (void)refresh{
    if (_myProject.isLoadingDetail) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_ProjectDetail_WithObj:_myProject andBlock:^(id data, NSError *error) {
        if (data) {
            weakSelf.myProject = data;
            weakSelf.navigationItem.rightBarButtonItem = weakSelf.myProject.is_public.boolValue? nil: [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addBtn_Artboard"] style:UIBarButtonItemStylePlain target:self action:@selector(tweetsBtnClicked)];
            [self refreshGitButtonsView];
            [weakSelf.myTableView reloadData];
        }
        [weakSelf.refreshControl endRefreshing];
    }];
}

- (void)tweetsBtnClicked{
    UserOrProjectTweetsViewController *vc = [UserOrProjectTweetsViewController new];
    vc.curTweets = [Tweets tweetsWithProject:self.myProject];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark Table M
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}

//header
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return section == 0? kLine_MinHeight: (section == 2 && !_myProject.is_public.boolValue)? 50: 15;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *headerView = [UIView new];
    headerView.backgroundColor = kColorTableSectionBg;
    if (section == 2 && !_myProject.is_public.boolValue) {
        UILabel *leftL = [UILabel labelWithFont:[UIFont systemFontOfSize:15] textColor:kColorDark3];
        leftL.text = @"代码";
        UILabel *rightL = [UILabel labelWithFont:[UIFont systemFontOfSize:14] textColor:kColorLightBlue];
        rightL.text = @"查看 README";
        __weak typeof(self) weakSelf = self;
        rightL.userInteractionEnabled = YES;
        [rightL bk_whenTapped:^{
            [weakSelf goToReadme];
        }];
        [headerView addSubview:leftL];
        [headerView addSubview:rightL];
        [leftL mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.offset(20);
            make.left.offset(kPaddingLeftWidth);
        }];
        [rightL mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(leftL);
            make.right.offset(-kPaddingLeftWidth);
        }];
    }
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return section == 3? 44: kLine_MinHeight;
}

//data
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger row = 0;
    if (section == 0) {
        row = 2;
    }else if (section == 1){
        row = _myProject.is_public.boolValue? _myProject.current_user_role_id.integerValue <= 70? 3: 4: 6;
    }else if (section == 2){
        row = _myProject.is_public.boolValue? 2: 4;
    }else{
        row = 1;
    }
    return row;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    __weak typeof(self) weakSelf = self;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            ProjectInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_ProjectInfoCell forIndexPath:indexPath];
            cell.curProject = _myProject;
            cell.projectBlock = ^(Project *clickedPro){
                [weakSelf gotoPro:clickedPro];
            };
            return cell;
        }else{
            ProjectDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_ProjectDescriptionCell forIndexPath:indexPath];
            [cell setDescriptionStr:_myProject.description_mine];
            return cell;
        }
    }else{
        NProjectItemCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_NProjectItemCell forIndexPath:indexPath];
        if (indexPath.section == 1){
            switch (indexPath.row) {
                case 0:
                    [cell setImageStr:@"project_item_activity" andTitle:@"动态"];
                    if (_myProject.un_read_activities_count.integerValue > 0) {
                        [cell addTip:_myProject.un_read_activities_count.stringValue];
                    }
                    break;
                case 1:
                    if (_myProject.is_public.boolValue) {
                        [cell setImageStr:@"project_item_topic" andTitle:@"讨论"];
                    }else{
                        [cell setImageStr:@"project_item_task" andTitle:@"任务"];
                    }
                    break;
                case 2:
                    if (_myProject.is_public.boolValue) {
                        [cell setImageStr:@"project_item_code" andTitle:@"代码"];
                    }else{
                        [cell setImageStr:@"project_item_file" andTitle:@"文件"];
                    }
                    break;
                case 3:
                    if (_myProject.is_public.boolValue) {
                        [cell setImageStr:@"project_item_member" andTitle:@"成员"];
                    }else{
                        [cell setImageStr:@"project_item_topic" andTitle:@"讨论"];
//                        [cell setImageStr:@"project_item_wiki" andTitle:@"Wiki"];
                    }
                    break;
                case 4:
                    [cell setImageStr:@"project_item_code" andTitle:@"代码"];
                    break;
                default:
                    [cell setImageStr:@"project_item_member" andTitle:@"成员"];
                    break;
            }
        }else if (indexPath.section == 2){
            if (_myProject.is_public.boolValue) {
                if (indexPath.row == 0) {
                    [cell setImageStr:@"project_item_readme" andTitle:@"README"];
                }else if (indexPath.row == 1){
                    [cell setImageStr:@"project_item_mr_pr" andTitle:@"Pull Request"];
                }
            }else{
                if (indexPath.row == 0) {
                    [cell setImageStr:@"project_item_code" andTitle:@"代码浏览"];
                }else if (indexPath.row == 1){
                    [cell setImageStr:@"project_item_branch" andTitle:@"分支管理"];
                }else if (indexPath.row == 2){
                    [cell setImageStr:@"project_item_tag" andTitle:@"发布管理"];
                }else if (indexPath.row == 3){
                    [cell setImageStr:@"project_item_mr_pr" andTitle:@"合并请求"];
                }
            }
        }else if (indexPath.section == 3){
            [cell setImageStr:@"project_item_reading" andTitle:@"本地阅读"];
        }
        FunctionTipsManager *ftm = [FunctionTipsManager shareManager];
        NSString *tipStr = [self p_TipStrForIndexPath:indexPath];
        if (tipStr && [ftm needToTip:tipStr]) {
            [cell addTipIcon];
        }
        [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:52];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    current_user_role_id = 75 是受限成员，不可访问代码
    CGFloat cellHeight = 0;
    if (indexPath.section == 0) {
        cellHeight = indexPath.row == 0? [ProjectInfoCell cellHeight]: [ProjectDescriptionCell cellHeightWithObj:_myProject];
    }else if (indexPath.section == 1){
//        if (!_myProject.is_public.boolValue && _myProject.current_user_role_id.integerValue <= 75 && indexPath.row == 4) {//私有项目的受限成员，不能查看代码
        if (indexPath.row == 4) {// section = 1 中的代码入口封掉
            cellHeight = 0;
        }else{
            cellHeight = [NProjectItemCell cellHeight];
        }
    }else{
        cellHeight = (!_myProject.is_public.boolValue && _myProject.current_user_role_id.integerValue <= 75)? 0: [NProjectItemCell cellHeight];//私有项目的受限成员，不能查看代码
    }
    return cellHeight;
}

//selected
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        // 如果是自己的项目才能进入设置
        if ([self.myProject.owner_id isEqual:[Login curLoginUser].id]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ProjectSetting" bundle:nil];
            UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"ProjectSettingVC"];
            [vc setValue:self.myProject forKey:@"project"];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }else if (indexPath.section == 1){
        [self goToIndex:indexPath.row];
    }else if (indexPath.section == 2){
        if (_myProject.is_public.boolValue) {
            if (indexPath.row == 0) {
                [self goToReadme];
            }else if (indexPath.row == 1){
                [self goTo_MR_PR];
            }
        }else{
            if (indexPath.row == 0) {
                [self goToIndex:ProjectViewTypeCodes];//私有公有 type 和 index 的对应关系有差异
            }else if (indexPath.row == 1){
                EACodeBranchListViewController *vc = [EACodeBranchListViewController new];
                vc.myProject = self.myProject;
                [self.navigationController pushViewController:vc animated:YES];
            }else if (indexPath.row == 2){
                EACodeReleaseListViewController *vc = [EACodeReleaseListViewController new];
                vc.myProject = self.myProject;
                [self.navigationController pushViewController:vc animated:YES];
            }else if (indexPath.row == 3){
                [self goTo_MR_PR];
            }
        }
    }else if (indexPath.section == 3){
        [self goToLocalRepo];
    }
    FunctionTipsManager *ftm = [FunctionTipsManager shareManager];
    NSString *tipStr = [self p_TipStrForIndexPath:indexPath];
    if (tipStr && [ftm needToTip:tipStr]) {
        [ftm markTiped:tipStr];
        NProjectItemCell *cell = (NProjectItemCell *)[tableView cellForRowAtIndexPath:indexPath];
        [cell removeTip];
    }
}

- (NSString *)p_TipStrForIndexPath:(NSIndexPath *)indexPath{
    NSString *tipStr = nil;
    return tipStr;
}

#pragma mark goTo VC
- (void)goToIndex:(NSInteger)index{
    if (index == 0) {
        __weak typeof(self) weakSelf = self;
        [[Coding_NetAPIManager sharedManager] request_Project_UpdateVisit_WithObj:_myProject andBlock:^(id data, NSError *error) {
            if (data) {
                weakSelf.myProject.un_read_activities_count = [NSNumber numberWithInteger:0];
            }
        }];
    }
//    if (index == 3 && _myProject.is_public && !_myProject.is_public.boolValue) {
//        WikiViewController *vc = [WikiViewController new];
//        vc.myProject = self.myProject;
//        [self.navigationController pushViewController:vc animated:YES];
//    }else{
        ProjectViewController *vc = [[ProjectViewController alloc] init];
        vc.myProject = self.myProject;
        vc.curIndex = index;
        [self.navigationController pushViewController:vc animated:YES];
//    }
}
- (void)gotoPro:(Project *)project{
    NProjectViewController *vc = [[NProjectViewController alloc] init];
    vc.myProject = project;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)goToReadme{
    CodeViewController *vc = [CodeViewController codeVCWithProject:_myProject andCodeFile:nil];
    vc.isReadMe = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)goTo_MR_PR{
    MRPRListViewController *vc = [[MRPRListViewController alloc] init];
    vc.curProject = self.myProject;
    vc.isMR = !_myProject.is_public.boolValue;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)goToLocalRepo{
    if (_myProject.isLocalRepoExist) {
        EALocalCodeListViewController *vc = [EALocalCodeListViewController new];
        vc.curPro = _myProject;
        vc.curRepo = _myProject.localRepo;
        vc.curURL = _myProject.localURL;
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        __weak typeof(self) weakSelf = self;
        [[UIActionSheet bk_actionSheetCustomWithTitle:@"本地阅读需要先 clone 代码，过程可能比较耗时，且不可中断，是否确认要 clone 代码？" buttonTitles:@[@"Clone"] destructiveTitle:nil cancelTitle:@"取消" andDidDismissBlock:^(UIActionSheet *sheet, NSInteger index) {
            if (index == 0) {
                [weakSelf cloneRepo];
            }
        }] showInView:self.view];
    }
}

- (void)cloneRepo{
    __weak typeof(self) weakSelf = self;
    MBProgressHUD *hud = [NSObject showHUDQueryStr:@"正在 clone..."];
    [_myProject gitCloneBlock:^(GTRepository *repo, NSError *error) {
        [NSObject hideHUDQuery];
        if (error) {
            [NSObject showError:error];
        }else{
            [weakSelf goToLocalRepo];
        }
    } progressBlock:^(const git_transfer_progress *progress, BOOL *stop) {
        hud.detailsLabelText = [NSString stringWithFormat:@"%d / %d", progress->received_objects, progress->total_objects];
    }];
}

#pragma mark Git_Btn
- (void)actionWithGitBtnIndex:(NSInteger)index{
    __weak typeof(self) weakSelf = self;
    switch (index) {
        case 0://Star
        {
            if (!_myProject.isStaring) {
                [[Coding_NetAPIManager sharedManager] request_StarProject:_myProject andBlock:^(id data, NSError *error) {
                    [weakSelf refreshGitButtonsView];
                }];
            }
        }
            break;
        case 1://Watch
        {
            if (!_myProject.isWatching) {
                [[Coding_NetAPIManager sharedManager] request_WatchProject:_myProject andBlock:^(id data, NSError *error) {
                    [weakSelf refreshGitButtonsView];
                }];
            }
        }
            break;
        default://Fork
        {
            [[UIActionSheet bk_actionSheetCustomWithTitle:@"fork将会将此项目复制到您的个人空间，确定要fork吗?" buttonTitles:@[@"确定"] destructiveTitle:nil cancelTitle:@"取消" andDidDismissBlock:^(UIActionSheet *sheet, NSInteger index) {
                if (index == 0) {
                    [[Coding_NetAPIManager sharedManager] request_ForkProject:_myProject andBlock:^(id data, NSError *error) {
                        [weakSelf refreshGitButtonsView];
                        if (data) {
                            NProjectViewController *vc = [[NProjectViewController alloc] init];
                            vc.myProject = data;
                            [weakSelf.navigationController pushViewController:vc animated:YES];
                        }
                    }];
                }
            }] showInView:self.view];
        }
            break;
    }
}

- (void)goToUsersWithGitBtnIndex:(NSInteger)index{
    if (index == 2) {
        //Fork
        ForkTreeViewController *vc = [ForkTreeViewController new];
        vc.project_owner_user_name = _myProject.owner_user_name;
        vc.project_name = _myProject.name;
        [self.navigationController pushViewController:vc animated:YES];
        NSString *path = [NSString stringWithFormat:@"api/user/%@/project/%@/git/forks", _myProject.owner_user_name, _myProject.name];
        NSLog(@"path: %@", path);
    }else{
        UsersViewController *vc = [[UsersViewController alloc] init];
        vc.curUsers = [Users usersWithProjectOwner:_myProject.owner_user_name projectName:_myProject.name Type:UsersTypeProjectStar + index];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)refreshGitButtonsView{
    self.gitButtonsView.curProject = self.myProject;
    CGFloat gitButtonsViewHeight = 0;
    if (self.myProject.is_public.boolValue) {
        gitButtonsViewHeight = CGRectGetHeight(self.gitButtonsView.frame) - 1;
    }
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, gitButtonsViewHeight, 0);
    self.myTableView.contentInset = insets;
    self.myTableView.scrollIndicatorInsets = insets;
}

@end
