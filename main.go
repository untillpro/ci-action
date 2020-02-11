/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

package main

import (
	"context"
	"fmt"
	"log"

	"github.com/google/go-github/v29/github"
)

func main() {
	ctx := context.Background()
	client := github.NewClient(nil)

	fmt.Println("## Organizations:")
	orgs, _, err := client.Organizations.List(ctx, "willnorris", nil)
	if err != nil {
		log.Fatal(err)
	}
	for _, org := range orgs {
		fmt.Println(org.GetLogin())
	}

	fmt.Println("## Repositories:")
	repos, _, err := client.Repositories.ListByOrg(ctx, "github", nil)
	if err != nil {
		println(err)
		fmt.Println(err)
		log.Fatal(err)
	}
	for _, repo := range repos {
		fmt.Println(repo.GetName())
	}

	fmt.Println("Hello world")
}
