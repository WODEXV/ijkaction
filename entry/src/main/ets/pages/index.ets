/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import router from '@ohos.router'

@Entry
@Component
struct indexPage {
  build() {
    Column() {
      Button('视频demo')
        .margin({ bottom: 20 })
        .width(200)
        .onClick(() => {
          router.pushUrl({ url: 'pages/SampleVideoListPage' })
        })
      Button('音频demo')
        .width(200)
        .onClick(() => {
          router.pushUrl({ url: 'pages/SampleAudioListPage' })
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Gray)
    .justifyContent(FlexAlign.Center)
  }
}