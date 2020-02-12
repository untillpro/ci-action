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
	"os"

	"github.com/google/go-github/v29/github"
	"github.com/urfave/cli/v2"
)

func main() {

	var organization string

	ctx := context.Background()
	client := github.NewClient(nil)

	app := &cli.App{
		Name:  "ci-action",
		Usage: "initialize repo for ci-action",
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:        "organization",
				Value:       "untillpro",
				Usage:       "GitHub organization",
				Destination: &organization,
			},
		},
		// Action: func(c *cli.Context) error {
		// 	return nil
		// },
		Commands: []*cli.Command{
			{
				Name:    "list",
				Aliases: []string{"l"},
				Usage:   "show repository list",
				Action: func(c *cli.Context) error {
					fmt.Println("organization", organization)
					fmt.Println("## Repositories:")
					repos, _, err := client.Repositories.ListByOrg(ctx, organization, nil)
					if err != nil {
						log.Fatal(err)
					}
					for _, repo := range repos {
						fmt.Println(repo.GetName())
					}
					return nil
				},
			},
		},
	}

	err := app.Run(os.Args)
	if err != nil {
		log.Fatal(err)
	}
}
